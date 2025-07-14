require 'sinatra'
require 'pg'
require 'bcrypt'
require 'date'

use Rack::MethodOverride
enable :sessions
set :session_secret, ENV.fetch('SESSION_SECRET') { "uma_chave_super_secreta_e_aleatoria_para_desenvolvimento" }

FAIXAS = ['Branca', 'Cinza/Branca', 'Cinza', 'Cinza/Preta', 'Amarela/Branca', 'Amarela', 'Amarela/Preta', 'Laranja/Branca', 'Laranja', 'Laranja/Preta', 'Verde/Branca', 'Verde', 'Verde/Preta', 'Azul', 'Roxa', 'Marrom', 'Preta']
TURMAS = ['Kids 2 a 3 anos', 'Kids', 'Adolescentes/Juvenil', 'Adultos', 'Feminino', 'Master/Sênior']

def create_db_client
  if ENV['DATABASE_URL']
    PG.connect(ENV['DATABASE_URL'])
  else
    PG.connect(host: 'db', user: 'jiujitsu_user', password: 'senha_forte_123', dbname: 'academia_jiujitsu_dev')
  end
end

helpers do
  def logged_in?
    !!session[:user_id]
  end

  def current_user
    return nil unless logged_in?
    client = create_db_client
    @current_user ||= client.exec_params('SELECT id, nome, email FROM usuarios WHERE id = $1', [session[:user_id]]).first
  ensure
    client.close if client
  end

  def h(text)
    Rack::Utils.escape_html(text.to_s)
  end
end

before do
  pass if ['/login', '/style.css', '/logo.png'].include? request.path_info
  redirect to('/login') unless logged_in?
end

get('/login') { erb :'auth/login', layout: false }

post '/login' do
  client = create_db_client
  begin
    puts "\n\n"
    puts "========================================"
    puts "🕵️  INICIANDO TENTATIVA DE LOGIN 🕵️"
    puts "========================================"

    email_digitado = params[:email]
    senha_digitada = params[:password]
    
    puts "[INFO] Email recebido do formulário: '#{email_digitado}'"
    puts "[INFO] Senha recebida do formulário: '#{senha_digitada}'"

    user = client.exec_params('SELECT * FROM usuarios WHERE email = $1', [email_digitado]).first
    
    if user
      puts "[SUCESSO] Usuário encontrado no banco: #{user.inspect}"
      stored_hash = user['password_digest']
      puts "[INFO] Hash armazenado no banco: '#{stored_hash}'"
      
      bcrypt_object = BCrypt::Password.new(stored_hash)
      puts "[INFO] Objeto BCrypt criado a partir do hash."

      if bcrypt_object == senha_digitada
        puts "[SUCESSO] 🎉 A SENHA CORRESPONDE! 🎉"
        session[:user_id] = user['id']
        redirect to('/')
      else
        puts "[ERRO] ❌ A SENHA NÃO CORRESPONDE! ❌"
        session[:mensagem_erro] = "Email ou senha inválidos."
        redirect to('/login')
      end
    else
      puts "[ERRO] ❌ Usuário com email '#{email_digitado}' NÃO FOI ENCONTRADO no banco de dados."
      session[:mensagem_erro] = "Email ou senha inválidos."
      redirect to('/login')
    end
  ensure
    puts "========================================"
    puts "🕵️  FIM DA TENTATIVA DE LOGIN 🕵️"
    puts "========================================"
    puts "\n\n"
    client.close if client
  end
end

get('/logout') do
  session.clear
  session[:mensagem_sucesso] = "Você saiu com segurança."
  redirect to('/login')
end

get '/' do
  client = create_db_client
  begin
    query = "SELECT id, nome, data_nascimento, cor_faixa, turma FROM alunos"
    conditions = []
    params_list = []
    param_count = 1

    if params[:busca] && !params[:busca].empty?
      conditions << "nome ILIKE $#{param_count}"
      params_list << "%#{params[:busca]}%"
      param_count += 1
    end

    if params[:faixa] && !params[:faixa].empty?
      conditions << "cor_faixa = $#{param_count}"
      params_list << params[:faixa]
      param_count += 1
    end

    if params[:turma] && !params[:turma].empty?
      conditions << "turma = $#{param_count}"
      params_list << params[:turma]
      param_count += 1
    end
    
    query += " WHERE #{conditions.join(' AND ')}" unless conditions.empty?
    query += " ORDER BY nome ASC"

    @alunos = client.exec_params(query, params_list).map do |aluno|
      hoje = Date.today
      data_nasc_str = aluno['data_nascimento']
      if data_nasc_str && !data_nasc_str.empty?
        begin
          data_nasc_obj = Date.parse(data_nasc_str)
          idade = hoje.year - data_nasc_obj.year
          idade -= 1 if hoje.yday < data_nasc_obj.yday
          aluno['idade'] = idade
        rescue Date::Error
          aluno['idade'] = 'Inválida'
        end
      else
        aluno['idade'] = 'N/A'
      end
      aluno
    end
    
    total_result = client.exec("SELECT COUNT(id) AS count FROM alunos")
    @total_alunos = total_result.any? ? total_result.first['count'].to_i : 0
    
    @faixas = FAIXAS
    @turmas = TURMAS
    erb :index
  ensure
    client.close if client
  end
end

post '/alunos' do
  client = create_db_client
  begin
    client.exec <<~SQL
      SELECT setval(
        pg_get_serial_sequence('alunos', 'id'),
        (SELECT COALESCE(MAX(id), 0) FROM alunos)
      );
    SQL

    bolsista = params['bolsista'] == 'on'

    query = <<~SQL
      INSERT INTO alunos(
        nome, data_nascimento, cor_faixa, turma,
        bolsista, saude_problema, saude_medicacao,
        saude_lesao, saude_substancia
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id
    SQL

    params_list = [
      params['nome'],
      params['data_nascimento'].empty? ? nil : params['data_nascimento'],
      params['cor_faixa'],
      params['turma'],
      bolsista,
      params['saude_problema'],
      params['saude_medicacao'],
      params['saude_lesao'],
      params['saude_substancia']
    ]

    result = client.exec_params(query, params_list)
    aluno_id = result.first['id']

    valor_mensalidade = bolsista ? 0.00 : 70.00
    client.exec_params(
      "INSERT INTO assinaturas(aluno_id, plano_id, valor_mensalidade, status)
       VALUES ($1, 1, $2, 'ativa')",
      [aluno_id, valor_mensalidade]
    )

    session[:mensagem_sucesso] = "Aluno cadastrado com sucesso!"
    redirect '/'
  ensure
    client.close if client
  end
end

get '/alunos/:id/editar' do
  client = create_db_client
  begin
    @aluno = client.exec_params("SELECT * FROM alunos WHERE id = $1", [params['id']]).first
    redirect '/' if @aluno.nil?

    if @aluno['data_nascimento'] && !@aluno['data_nascimento'].empty?
      @aluno['data_nascimento'] = Date.parse(@aluno['data_nascimento'])
    end

    @faixas = FAIXAS
    @turmas = TURMAS
    erb :editar_aluno
  ensure
    client.close if client
  end
end


put '/alunos/:id' do
  client = create_db_client
  begin
    bolsista = params['bolsista'] == 'on'
    
    query = <<~SQL
      UPDATE alunos SET
        nome = $1,
        data_nascimento = $2,
        cor_faixa = $3,
        turma = $4,
        bolsista = $5,
        saude_problema = $6,
        saude_medicacao = $7,
        saude_lesao = $8,
        saude_substancia = $9
      WHERE id = $10
    SQL
    params_list = [
      params['nome'],
      params['data_nascimento'].empty? ? nil : params['data_nascimento'],
      params['cor_faixa'],
      params['turma'],
      bolsista,
      params['saude_problema'],
      params['saude_medicacao'],
      params['saude_lesao'],
      params['saude_substancia'],
      params['id']
    ]

    client.exec_params(query, params_list)
    session[:mensagem_sucesso] = "Dados do aluno atualizados com sucesso!"
    redirect "/alunos/#{params['id']}"
  ensure
    client.close if client
  end
end

delete '/alunos/:id' do
  client = create_db_client
  begin
    client.exec_params("DELETE FROM alunos WHERE id = $1", [params['id']])
    session[:mensagem_sucesso] = "Aluno removido com sucesso!"
    redirect '/'
  ensure
    client.close if client
  end
end

get '/alunos/:id' do
  client = create_db_client
  begin
    @aluno = client.exec_params("SELECT * FROM alunos WHERE id = $1", [params['id']]).first
    redirect '/' if @aluno.nil?

    @assinatura = client.exec_params(
      "SELECT * FROM assinaturas WHERE aluno_id = $1 AND status = 'ativa'",
      [params['id']]
    ).first

    if @assinatura
      ultimo_pag = client.exec_params(
        "SELECT data_pagamento FROM pagamentos WHERE assinatura_id = $1 ORDER BY data_pagamento DESC LIMIT 1",
        [@assinatura['id']]
      ).first

      if ultimo_pag
        vencimento = Date.parse(ultimo_pag['data_pagamento']) + 30
        @status_mensalidade = Date.today > vencimento ? "Atrasado" : "Em Dia"
        @cor_status = "status-#{@status_mensalidade.downcase.split.first}"
      else
        @status_mensalidade = "Pendente"
        @cor_status = "status-pendente"
      end

      @historico_pagamentos = client.exec_params(
        "SELECT * FROM pagamentos WHERE assinatura_id = $1 ORDER BY data_pagamento DESC",
        [@assinatura['id']]
      )
    else
      @status_mensalidade = "Inativa"
      @cor_status = "status-inativo"
    end

    @graduacoes = client.exec_params(
      "SELECT * FROM graduacoes WHERE aluno_id = $1 ORDER BY data_graduacao DESC",
      [params['id']]
    )

    total_aulas_result = client.exec("SELECT COUNT(id) as count FROM aulas")
    @total_aulas = total_aulas_result.first['count'].to_i
    presencas_result = client.exec_params(
      "SELECT COUNT(id) as count FROM presencas WHERE aluno_id = $1 AND presente = TRUE",
      [params['id']]
    )
    @presencas = presencas_result.first['count'].to_i
    @faltas = @total_aulas - @presencas

    erb :'alunos/show'
  ensure
    client.close if client
  end
end

get '/aulas' do
  client = create_db_client
  begin
    @aulas  = client.exec("SELECT * FROM aulas ORDER BY data_aula DESC")
    @turmas = TURMAS
    erb :'aulas/index'
  ensure
    client.close if client
  end
end

post '/aulas' do
  client = create_db_client
  begin
    turma_aula = params['turma'].empty? ? nil : params['turma']
    todas_turmas = params['todas_turmas'] == 'on'

    result = client.exec_params(
      "INSERT INTO aulas (data_aula, turma, descricao) VALUES ($1, $2, $3) RETURNING id",
      [params['data_aula'], turma_aula, params['descricao']]
    )
    aula_id = result.first['id']

    if todas_turmas
      alunos_q = client.exec("SELECT id FROM alunos")
    elsif turma_aula
      alunos_q = client.exec_params("SELECT id FROM alunos WHERE turma = $1", [turma_aula])
    else
      alunos_q = client.exec("SELECT id FROM alunos")
    end

    alunos_q.each do |a|
      client.exec_params(
        "INSERT INTO presencas (aula_id, aluno_id, presente) VALUES ($1, $2, FALSE) ON CONFLICT (aluno_id, aula_id) DO NOTHING",
        [aula_id, a['id']]
      )
    end

    session[:mensagem_sucesso] = "Aula criada com sucesso!"
    redirect "/aulas/#{aula_id}"
  ensure
    client.close if client
  end
end

get '/aulas/:id' do
  client = create_db_client
  begin
    @aula = client.exec_params("SELECT * FROM aulas WHERE id = $1", [params['id']]).first
    redirect '/aulas' if @aula.nil?
    @lista_presenca = client.exec_params(
      "SELECT p.aluno_id AS id, a.nome, p.presente FROM presencas p JOIN alunos a ON p.aluno_id = a.id WHERE p.aula_id = $1 ORDER BY a.nome",
      [params['id']]
    )
    erb :'aulas/show'
  ensure
    client.close if client
  end
end

post '/aulas/:id/presencas' do
  client = create_db_client
  begin
    aula_id = params['id']
    client.exec_params("UPDATE presencas SET presente = FALSE WHERE aula_id = $1", [aula_id])

    (params['presentes'] || []).each do |aluno_id|
      client.exec_params(
        "UPDATE presencas SET presente = TRUE WHERE aula_id = $1 AND aluno_id = $2",
        [aula_id, aluno_id]
      )
    end

    session[:mensagem_sucesso] = "Lista de presença atualizada!"
    redirect "/aulas/#{aula_id}"
  ensure
    client.close if client
  end
end

post '/pagamentos' do
  client = create_db_client
  begin
    client.exec_params(
      "INSERT INTO pagamentos(assinatura_id, valor_pago, data_pagamento) VALUES ($1, $2, $3)",
      [params['assinatura_id'], params['valor_pago'], params['data_pagamento']]
    )
    session[:mensagem_sucesso] = "Pagamento registrado com sucesso!"
    redirect "/alunos/#{params['aluno_id']}"
  ensure
    client.close if client
  end
end

post '/graduacoes' do
  client = create_db_client
  begin
    client.exec_params(
      "INSERT INTO graduacoes(aluno_id, faixa, data_graduacao) VALUES ($1, $2, $3)",
      [params['aluno_id'], params['faixa'], params['data_graduacao']]
    )
    client.exec_params(
      "UPDATE alunos SET cor_faixa = $1 WHERE id = $2",
      [params['faixa'], params['aluno_id']]
    )
    session[:mensagem_sucesso] = "Graduação registrada com sucesso!"
    redirect "/alunos/#{params['aluno_id']}"
  ensure
    client.close if client
  end
end
