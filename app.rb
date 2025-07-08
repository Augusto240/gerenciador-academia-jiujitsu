require 'sinatra'
require 'mysql2'
require 'date' 

use Rack::MethodOverride
enable :sessions

FAIXAS = ['Branca', 'Cinza/Branca', 'Cinza', 'Cinza/Preta', 'Amarela/Branca', 'Amarela',
          'Amarela/Preta', 'Laranja/Branca', 'Laranja', 'Laranja/Preta', 'Verde/Branca', 'Verde', 'Verde/Preta',
          'Azul', 'Roxa', 'Marrom', 'Preta', 'Vermelha/Preta', 'Vermelha/Branca', 'Vermelha']
TURMAS = ['Kids 2 a 3 anos', 'Kids', 'Adolescentes/Juvenil', 'Adultos', 'Feminino', 'Master/Sênior']

def create_db_client
  Mysql2::Client.new(
    host:     ENV['DATABASE_HOST'],
    username: ENV['DATABASE_USER'],
    password: ENV['DATABASE_PASSWORD'],
    database: ENV['DATABASE_NAME']
  )
end

get '/' do
  client = create_db_client
  
  query_base = "SELECT id, nome, data_nascimento, cor_faixa, turma FROM alunos"
  
  if params[:busca] && !params[:busca].empty?
    busca_segura = client.escape(params[:busca])
    query_base += " WHERE nome LIKE '%#{busca_segura}%'"
  end
  
  query_base += " ORDER BY nome ASC"

  alunos_do_banco = client.query(query_base)

  @alunos = alunos_do_banco.map do |aluno|
    hoje = Date.today
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

get '/alunos/:id' do
  client = create_db_client
  id = params['id']
  
  @aluno = client.query("SELECT * FROM alunos WHERE id = #{id}").first
  redirect '/' if @aluno.nil?

  @assinatura = client.query("SELECT * FROM assinaturas WHERE aluno_id = #{id} AND status = 'ativa'").first
  if @assinatura
    ultimo_pagamento = client.query("SELECT data_pagamento FROM pagamentos WHERE assinatura_id = #{@assinatura['id']} ORDER BY data_pagamento DESC LIMIT 1").first
    
    if ultimo_pagamento
      vencimento = ultimo_pagamento['data_pagamento'] + 30
      if Date.today > vencimento
        @status_mensalidade = "Atrasado"
        @cor_status = "status-atrasado"
      else
        @status_mensalidade = "Em Dia"
        @cor_status = "status-em-dia"
      end
    else
      @status_mensalidade = "Pendente"
      @cor_status = "status-pendente"
    end
    @historico_pagamentos = client.query("SELECT * FROM pagamentos WHERE assinatura_id = #{@assinatura['id']} ORDER BY data_pagamento DESC")
  else
    @status_mensalidade = "Inativa"
    @cor_status = "status-inativo"
  end

  # Busca o histórico de graduações
  @graduacoes = client.query("SELECT * FROM graduacoes WHERE aluno_id = #{id} ORDER BY data_graduacao DESC")
  
  erb :'alunos/show'
end

post '/alunos' do
  client = create_db_client
  nome = client.escape(params['nome'])
  data_nascimento = client.escape(params['data_nascimento'])
  cor_faixa = client.escape(params['cor_faixa'])
  turma = client.escape(params['turma'])

  query_aluno = "INSERT INTO alunos(nome, data_nascimento, cor_faixa, turma) VALUES ('#{nome}', '#{data_nascimento}', '#{cor_faixa}', '#{turma}')"
  client.query(query_aluno)
  
  aluno_id = client.last_id

  query_assinatura = "INSERT INTO assinaturas(aluno_id, plano_id, valor_mensalidade, status) VALUES (#{aluno_id}, 1, 70.00, 'ativa')"
  client.query(query_assinatura)

  session[:mensagem_sucesso] = "Aluno cadastrado com sucesso! Assinatura ativada."
  redirect '/' 
end

get '/alunos/:id/editar' do
  client = create_db_client
  id = params['id']
  @aluno = client.query("SELECT * FROM alunos WHERE id = #{id}").first
  @faixas = FAIXAS
  @turmas = TURMAS
  erb :editar_aluno
end

put '/alunos/:id' do
  client = create_db_client
  id = params['id']
  nome = client.escape(params['nome'])
  data_nascimento = client.escape(params['data_nascimento'])
  cor_faixa = client.escape(params['cor_faixa'])
  turma = client.escape(params['turma'])
  
  query = "UPDATE alunos SET nome = '#{nome}', data_nascimento = '#{data_nascimento}', cor_faixa = '#{cor_faixa}', turma = '#{turma}' WHERE id = #{id}"
  client.query(query)
  session[:mensagem_sucesso] = "Dados do aluno atualizados com sucesso!"
  redirect "/alunos/#{id}"
end

delete '/alunos/:id' do
  client = create_db_client
  id = params['id']
  client.query("DELETE FROM alunos WHERE id = #{id}")
  session[:mensagem_sucesso] = "Aluno removido com sucesso!"
  redirect '/'
end

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