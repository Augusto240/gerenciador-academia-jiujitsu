#!/usr/bin/env ruby
require 'pg'
require 'bcrypt'

# Conectar ao banco de dados
db_url = ENV['DATABASE_URL'] || 'postgres://jiujitsu_user:senha_forte_123@localhost:5433/academia_jiujitsu_dev'
conn = PG.connect(db_url)

# Primeiro vamos verificar a estrutura da tabela para saber o nome correto da coluna
colunas = conn.exec("SELECT column_name FROM information_schema.columns WHERE table_name = 'usuarios'").map { |row| row['column_name'] }
puts "Colunas disponíveis na tabela usuarios: #{colunas.join(', ')}"

# Identificar o nome da coluna de senha (provavelmente é 'senha' em vez de 'senha_hash')
senha_coluna = colunas.find { |col| col.include?('senha') } || 'senha'
admin_coluna = colunas.find { |col| col == 'admin' } || 'admin'

puts "Usando coluna '#{senha_coluna}' para senha e '#{admin_coluna}' para admin"

# Verificar se o usuário admin já existe
result = conn.exec_params("SELECT * FROM usuarios WHERE email = $1", ['admin@jpteam.com'])

if result.ntuples == 0
  # Criar senha hash
  senha_hash = BCrypt::Password.create('admin123')
  
  # Inserir usuário admin
  conn.exec_params(
    "INSERT INTO usuarios (nome, email, #{senha_coluna}, #{admin_coluna}) VALUES ($1, $2, $3, $4)",
    ['Admin JPM', 'admin@jpteam.com', senha_hash, true]
  )
  
  puts "Usuário administrador criado com sucesso!"
else
  puts "Usuário administrador já existe."
end

conn.close