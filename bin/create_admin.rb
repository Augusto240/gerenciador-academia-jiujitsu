#!/usr/bin/env ruby
require 'pg'
require 'bcrypt'

# Conectar ao banco de dados
db_url = ENV['DATABASE_URL'] || 'postgres://jiujitsu_user:senha_forte_123@localhost:5433/academia_jiujitsu_dev'
conn = PG.connect(db_url)

# Criar uma nova senha hash
nova_senha = "admin123"
senha_hash = BCrypt::Password.create(nova_senha)

# Atualizar a senha do administrador
result = conn.exec_params(
  "UPDATE usuarios SET password_digest = $1 WHERE email = $2 RETURNING id",
  [senha_hash, 'admin@jpteam.com']
)

if result.ntuples > 0
  puts "✅ Senha do administrador atualizada com sucesso!"
  puts "Email: admin@jpteam.com"
  puts "Senha: #{nova_senha}"
else
  puts "❌ Usuário admin@jpteam.com não encontrado!"
end

conn.close