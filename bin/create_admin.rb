#!/usr/bin/env ruby
require 'pg'
require 'bcrypt'
require 'securerandom'

# Conectar ao banco de dados
db_url = ENV['DATABASE_URL']

unless db_url
  if ENV['RACK_ENV'] == 'production'
    raise "DATABASE_URL não configurada!"
  else
    db_url = 'postgres://jiujitsu_user:senha_forte_123@localhost:5433/academia_jiujitsu_dev'
  end
end

# Senha do admin - em produção usar variável de ambiente ou gerar uma aleatória
admin_password = ENV['ADMIN_PASSWORD'] || (ENV['RACK_ENV'] == 'production' ? SecureRandom.hex(16) : 'admin123')

conn = PG.connect(db_url)

# Verificar se o usuário admin já existe
result = conn.exec_params("SELECT * FROM usuarios WHERE email = $1", ['admin@jpteam.com'])

if result.ntuples == 0
  # Criar senha hash
  senha_hash = BCrypt::Password.create(admin_password)
  
  # Inserir usuário admin
  conn.exec_params(
    "INSERT INTO usuarios (nome, email, password_digest, admin) VALUES ($1, $2, $3, $4)",
    ['Admin JPM', 'admin@jpteam.com', senha_hash, true]
  )
  
  puts "Usuário administrador criado com sucesso!"
  puts "IMPORTANTE: Mude a senha padrão imediatamente em produção!"
else
  puts "Usuário administrador já existe."
end

conn.close