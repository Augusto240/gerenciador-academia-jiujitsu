#!/usr/bin/env ruby
require 'pg'
require 'bcrypt'

# Conexão inteligente: Usa DATABASE_URL se existir (Render), 
# senão usa as variáveis do Docker Compose (Desenvolvimento Local)
if ENV['DATABASE_URL']
  conn = PG.connect(ENV['DATABASE_URL'])
else
  conn = PG.connect(
    host: ENV.fetch('DATABASE_HOST', 'db'),
    user: ENV.fetch('DATABASE_USER', 'jiujitsu_user'),
    password: ENV.fetch('DATABASE_PASSWORD', 'senha_forte_123'),
    dbname: ENV.fetch('DATABASE_NAME', 'academia_jiujitsu_dev'),
    port: 5432 # Porta interna padrão do Postgres
  )
end

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