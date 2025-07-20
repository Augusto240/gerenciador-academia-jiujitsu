#!/usr/bin/env ruby
require 'pg'
require 'bcrypt'

# Conectar ao banco de dados
db_url = ENV['DATABASE_URL'] || 'postgres://jiujitsu_user:senha_forte_123@localhost:5433/academia_jiujitsu_dev'
conn = PG.connect(db_url)

# Verificar se o usuário admin já existe
result = conn.exec_params("SELECT * FROM usuarios WHERE email = $1", ['admin@jpteam.com'])

if result.ntuples == 0
  # Criar senha hash
  senha_hash = BCrypt::Password.create('admin123')
  
  # Inserir usuário admin
  conn.exec_params(
    "INSERT INTO usuarios (nome, email, senha_hash, admin) VALUES ($1, $2, $3, $4)",
    ['Admin JPM', 'admin@jpteam.com', senha_hash, true]
  )
  
  puts "Usuário administrador criado com sucesso!"
else
  puts "Usuário administrador já existe."
end

conn.close