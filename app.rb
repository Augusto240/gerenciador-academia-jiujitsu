require 'sinatra'
require 'mysql2'

use Rack::MethodOverride

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
  @alunos = client.query("SELECT id, nome, DATE_FORMAT(data_nascimento, '%d/%m/%Y') AS data_formatada, cor_faixa, turma FROM alunos ORDER BY nome ASC")
  erb :index
end

post '/alunos' do
  client = create_db_client
  nome = client.escape(params['nome'])
  data_nascimento = client.escape(params['data_nascimento'])
  cor_faixa = client.escape(params['cor_faixa'])
  turma = client.escape(params['turma'])

  query = "INSERT INTO alunos(nome, data_nascimento, cor_faixa, turma) VALUES ('#{nome}', '#{data_nascimento}', '#{cor_faixa}', '#{turma}')"
  client.query(query)

  redirect '/' 
end

get '/alunos/:id/editar' do
  client = create_db_client
  id = params['id']
  @aluno = client.query("SELECT * FROM alunos WHERE id = #{id}").first
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
  
  redirect '/'
end

delete '/alunos/:id' do
  client = create_db_client
  id = params['id']
  client.query("DELETE FROM alunos WHERE id = #{id}")
  
  redirect '/'
end

get '/alunos' do
    redirect '/'
end