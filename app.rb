require 'sinatra'
require 'mysql2'

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

  alunos_do_banco = client.query("SELECT id, nome, data_nascimento, cor_faixa, turma FROM alunos ORDER BY nome ASC")

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

post '/alunos' do
  client = create_db_client
  nome = client.escape(params['nome'])
  data_nascimento = client.escape(params['data_nascimento'])
  cor_faixa = client.escape(params['cor_faixa'])
  turma = client.escape(params['turma'])

  query = "INSERT INTO alunos(nome, data_nascimento, cor_faixa, turma) VALUES ('#{nome}', '#{data_nascimento}', '#{cor_faixa}', '#{turma}')"
  client.query(query)
  session[:mensagem_sucesso] = "Aluno cadastrado com sucesso!"
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
  redirect '/'
end

delete '/alunos/:id' do
  client = create_db_client
  id = params['id']
  client.query("DELETE FROM alunos WHERE id = #{id}")
  session[:mensagem_sucesso] = "Aluno removido com sucesso!"
  redirect '/'
end

get '/alunos' do
    redirect '/'
end