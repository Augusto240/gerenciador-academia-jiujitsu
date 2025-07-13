# app.rb
require 'sinatra'
require 'mysql2'
require 'date'
require 'bigdecimal'

# DEBUG: Imprimir variáveis de ambiente para verificar se estão sendo carregadas
puts "=> DATABASE_HOST: #{ENV['DATABASE_HOST']}"
puts "=> DATABASE_USER: #{ENV['DATABASE_USER']}"
puts "=> DATABASE_NAME: #{ENV['DATABASE_NAME']}"
puts "=> Conectando ao banco de dados..."

use Rack::MethodOverride
enable :sessions

# --- CONSTANTES DE OPÇÕES ---
FAIXAS = ['Branca', 'Cinza/Branca', 'Cinza', 'Cinza/Preta', 'Amarela/Branca', 'Amarela',
          'Amarela/Preta', 'Laranja/Branca', 'Laranja', 'Laranja/Preta', 'Verde/Branca', 'Verde', 'Verde/Preta',
          'Azul', 'Roxa', 'Marrom', 'Preta', 'Vermelha/Preta', 'Vermelha/Branca', 'Vermelha']
TURMAS = ['Kids 2 a 3 anos', 'Kids', 'Adolescentes/Juvenil', 'Adultos', 'Feminino', 'Master/Sênior']

# --- CONEXÃO COM O BANCO ---
def create_db_client
  Mysql2::Client.new(
    host:     ENV['DATABASE_HOST'],
    username: ENV['DATABASE_USER'],
    password: ENV['DATABASE_PASSWORD'],
    database: ENV['DATABASE_NAME']
  )
  puts "=> Conexão com o banco de dados bem-sucedida!"
rescue => e
  puts "!!!!!!!!!! FALHA AO CONECTAR AO BANCO: #{e.message}"
end
# --- ROTA PRINCIPAL (COM BUSCA E FILTROS) ---
get '/' do
  client = create_db_client
  query      = "SELECT id, nome, data_nascimento, cor_faixa, turma, bolsista FROM alunos"
  conditions = []

  if params[:busca] && !params[:busca].empty?
    conditions << "nome LIKE '%#{client.escape(params[:busca])}%'"
  end
  if params[:faixa] && !params[:faixa].empty?
    conditions << "cor_faixa = '#{client.escape(params[:faixa])}'"
  end
  if params[:turma] && !params[:turma].empty?
    conditions << "turma = '#{client.escape(params[:turma])}'"
  end

  query += " WHERE #{conditions.join(' AND ')}" if conditions.any?
  query += " ORDER BY nome ASC"

  alunos_do_banco = client.query(query)
  @total_alunos   = client.query("SELECT COUNT(id) AS count FROM alunos").first['count']

  @alunos = alunos_do_banco.map do |aluno|
    hoje      = Date.today
    data_nasc = aluno['data_nascimento']
    if data_nasc
      idade = hoje.year - data_nasc.year
      idade -= 1 if hoje.yday < data_nasc.yday
      aluno['idade'] = idade
    else
      aluno['idade'] = 'N/A'
    end
    aluno
  end

  @faixas = FAIXAS
  @turmas = TURMAS
  erb :index
end

# --- CRUD DE ALUNOS ---
post '/alunos' do
  client = create_db_client
  nome = client.escape(params['nome'])
  data_nascimento = params['data_nascimento'].empty? ? "NULL" : "'#{client.escape(params['data_nascimento'])}'"
  cor_faixa = client.escape(params['cor_faixa'])
  turma = client.escape(params['turma'])
  bolsista = params['bolsista'] == 'on' ? 1 : 0

  # Novos campos de anamnese
  saude_problema = client.escape(params['saude_problema'])
  saude_medicacao = client.escape(params['saude_medicacao'])
  saude_lesao = client.escape(params['saude_lesao'])
  saude_substancia = client.escape(params['saude_substancia'])

  query_aluno = "INSERT INTO alunos(nome, data_nascimento, cor_faixa, turma, bolsista, saude_problema, saude_medicacao, saude_lesao, saude_substancia) VALUES ('#{nome}', #{data_nascimento}, '#{cor_faixa}', '#{turma}', #{bolsista}, '#{saude_problema}', '#{saude_medicacao}', '#{saude_lesao}', '#{saude_substancia}')"
  client.query(query_aluno)
  
  aluno_id = client.last_id
  valor_mensalidade = bolsista == 1 ? 0.00 : 70.00

  query_assinatura = "INSERT INTO assinaturas(aluno_id, plano_id, valor_mensalidade, status) VALUES (#{aluno_id}, 1, #{valor_mensalidade}, 'ativa')"
  client.query(query_assinatura)

  session[:mensagem_sucesso] = "Aluno cadastrado com sucesso! Assinatura ativada."
  redirect '/' 
end

get '/alunos/:id/editar' do
  client  = create_db_client
  @aluno  = client.query("SELECT * FROM alunos WHERE id = #{params['id']}").first
  @faixas = FAIXAS
  @turmas = TURMAS
  erb :editar_aluno
end

put '/alunos/:id' do
  client = create_db_client
  id = params['id']
  nome = client.escape(params['nome'])
  data_nascimento = params['data_nascimento'].empty? ? "NULL" : "'#{client.escape(params['data_nascimento'])}'"
  cor_faixa = client.escape(params['cor_faixa'])
  turma = client.escape(params['turma'])
  bolsista = params['bolsista'] == 'on' ? 1 : 0

  # Novos campos de anamnese
  saude_problema = client.escape(params['saude_problema'])
  saude_medicacao = client.escape(params['saude_medicacao'])
  saude_lesao = client.escape(params['saude_lesao'])
  saude_substancia = client.escape(params['saude_substancia'])

  query = "UPDATE alunos SET nome = '#{nome}', data_nascimento = #{data_nascimento}, cor_faixa = '#{cor_faixa}', turma = '#{turma}', bolsista = #{bolsista}, saude_problema = '#{saude_problema}', saude_medicacao = '#{saude_medicacao}', saude_lesao = '#{saude_lesao}', saude_substancia = '#{saude_substancia}' WHERE id = #{id}"
  client.query(query)
  
  session[:mensagem_sucesso] = "Dados do aluno atualizados com sucesso!"
  redirect "/alunos/#{id}"
end


delete '/alunos/:id' do
  client = create_db_client
  client.query("DELETE FROM alunos WHERE id = #{params['id']}")
  session[:mensagem_sucesso] = "Aluno removido com sucesso!"
  redirect '/'
end

# --- PÁGINA DE DETALHES DO ALUNO ---
get '/alunos/:id' do
  client    = create_db_client
  @aluno    = client.query("SELECT * FROM alunos WHERE id = #{params['id']}").first
  redirect '/' if @aluno.nil?

  # Mensalidades
  @assinatura = client.query("SELECT * FROM assinaturas WHERE aluno_id = #{@aluno['id']} AND status = 'ativa'").first
  if @assinatura
    ultimo_pag = client.query("SELECT data_pagamento FROM pagamentos WHERE assinatura_id = #{@assinatura['id']} ORDER BY data_pagamento DESC LIMIT 1").first
    if ultimo_pag
      venc = ultimo_pag['data_pagamento'] + 30
      @status_mensalidade = Date.today > venc ? "Atrasado" : "Em Dia"
      @cor_status         = "status-#{@status_mensalidade.downcase}"
    else
      @status_mensalidade = "Pendente"
      @cor_status         = "status-pendente"
    end
    @historico_pagamentos = client.query("SELECT * FROM pagamentos WHERE assinatura_id = #{@assinatura['id']} ORDER BY data_pagamento DESC")
  else
    @status_mensalidade = "Inativa"
    @cor_status         = "status-inativo"
  end

  # Graduações
  @graduacoes = client.query("SELECT * FROM graduacoes WHERE aluno_id = #{@aluno['id']} ORDER BY data_graduacao DESC")

  # Presença
  @total_aulas = client.query("SELECT COUNT(id) AS count FROM aulas").first['count']
  @presencas   = client.query("SELECT COUNT(id) AS count FROM presencas WHERE aluno_id = #{@aluno['id']} AND presente = TRUE").first['count']
  @faltas      = @total_aulas - @presencas

  erb :'alunos/show'
end

# --- ROTAS DE AULAS E PRESENÇA ---
get '/aulas' do
  client = create_db_client
  @aulas = client.query("SELECT * FROM aulas ORDER BY data_aula DESC")
  erb :'aulas/index'
end

post '/aulas' do
  client     = create_db_client
  data_aula  = client.escape(params['data_aula'])
  descricao  = client.escape(params['descricao'])
  turma_sel  = params['turma']
  todas      = params['todas_turmas'] == 'on'

  # Cria a aula
  client.query("INSERT INTO aulas (data_aula, descricao) VALUES ('#{data_aula}', '#{descricao}')")
  aula_id = client.last_id

  # Decide quais alunos incluir na lista de presença:
  if todas
    alunos_ids = client.query("SELECT id FROM alunos").map { |a| a['id'] }
  elsif turma_sel && !turma_sel.empty?
    safe_turma = client.escape(turma_sel)
    alunos_ids = client.query("SELECT id FROM alunos WHERE turma = '#{safe_turma}'").map { |a| a['id'] }
  else
    alunos_ids = client.query("SELECT id FROM alunos").map { |a| a['id'] }
  end

  # Inicializa presença FALSE
  alunos_ids.each do |aluno_id|
    client.query("INSERT INTO presencas (aula_id, aluno_id, presente) VALUES (#{aula_id}, #{aluno_id}, FALSE)")
  end

  session[:mensagem_sucesso] =
    if todas
      "Aula criada para **todos** os alunos! Agora registre a presença."
    else
      "Aula criada para a turma “#{turma_sel}”! Agora registre a presença."
    end

  redirect "/aulas/#{aula_id}"
end

get '/aulas/:id' do
  client          = create_db_client
  @aula           = client.query("SELECT * FROM aulas WHERE id = #{params['id']}").first
  redirect '/aulas' if @aula.nil?
  @lista_presenca = client.query(
    "SELECT p.id, a.nome, p.presente FROM presencas p JOIN alunos a ON p.aluno_id = a.id WHERE p.aula_id = #{params['id']} ORDER BY a.nome"
  )
  erb :'aulas/show'
end

post '/aulas/:id/presencas' do
  client  = create_db_client
  aula_id = params['id'].to_i

  client.query("UPDATE presencas SET presente = FALSE WHERE aula_id = #{aula_id}")
  Array(params['presentes']).each do |pid|
    client.query("UPDATE presencas SET presente = TRUE WHERE id = #{pid.to_i}")
  end

  session[:mensagem_sucesso] = "Lista de presença atualizada!"
  redirect "/aulas/#{aula_id}"
end

# --- ROTAS DE PAGAMENTOS E GRADUAÇÕES ---
post '/pagamentos' do
  client = create_db_client
  assinatura_id = params['assinatura_id']
  aluno_id = params['aluno_id']
  valor_pago = client.escape(params['valor_pago'])
  data_pagamento = client.escape(params['data_pagamento'])
  
  query = "INSERT INTO pagamentos(assinatura_id, valor_pago, data_pagamento) VALUES (#{assinatura_id}, '#{valor_pago}', '#{data_pagamento}')"
  client.query(query)
  
  session[:mensagem_sucesso] = "Pagamento registrado com sucesso!"
  redirect "/alunos/#{aluno_id}"
end

post '/graduacoes' do
  client = create_db_client
  aluno_id = params['aluno_id']
  faixa = client.escape(params['faixa'])
  data_graduacao = client.escape(params['data_graduacao'])

  insert_query = "INSERT INTO graduacoes(aluno_id, faixa, data_graduacao) VALUES (#{aluno_id}, '#{faixa}', '#{data_graduacao}')"
  client.query(insert_query)

  update_query = "UPDATE alunos SET cor_faixa = '#{faixa}' WHERE id = #{aluno_id}"
  client.query(update_query)
  
  session[:mensagem_sucesso] = "Graduação registrada com sucesso!"
  redirect "/alunos/#{aluno_id}"
end