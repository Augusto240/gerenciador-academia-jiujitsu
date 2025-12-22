#!/usr/bin/env ruby
# Script de migração segura para adicionar novas colunas/tabelas
# Este script NÃO apaga dados existentes

require 'pg'

puts "🔄 Iniciando migração segura do banco de dados..."

# Conectar ao banco - suporta DATABASE_URL ou variáveis individuais
db_url = ENV['DATABASE_URL']

conn = if db_url
  PG.connect(db_url)
else
  PG.connect(
    host: ENV.fetch('DATABASE_HOST', 'db'),
    user: ENV.fetch('DATABASE_USER', 'jiujitsu_user'),
    password: ENV.fetch('DATABASE_PASSWORD', 'senha_forte_123'),
    dbname: ENV.fetch('DATABASE_NAME', 'academia_jiujitsu_dev')
  )
end

def column_exists?(conn, table, column)
  result = conn.exec_params(<<~SQL, [table, column])
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = $1 AND column_name = $2
  SQL
  result.ntuples > 0
end

def table_exists?(conn, table)
  result = conn.exec_params(<<~SQL, [table])
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_name = $1
  SQL
  result.ntuples > 0
end

# ==========================================
# MIGRAÇÕES - Adicione novas migrações aqui
# ==========================================

puts "\n📋 Verificando migrações necessárias..."

# 1. Adicionar coluna 'admin' em usuarios
if !column_exists?(conn, 'usuarios', 'admin')
  puts "  ➕ Adicionando coluna 'admin' em usuarios..."
  conn.exec("ALTER TABLE usuarios ADD COLUMN admin BOOLEAN DEFAULT FALSE")
  puts "     ✅ Coluna 'admin' adicionada!"
else
  puts "  ✓ Coluna 'admin' já existe em usuarios"
end

# 2. Adicionar coluna 'created_at' em usuarios
if !column_exists?(conn, 'usuarios', 'created_at')
  puts "  ➕ Adicionando coluna 'created_at' em usuarios..."
  conn.exec("ALTER TABLE usuarios ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
  puts "     ✅ Coluna 'created_at' adicionada!"
else
  puts "  ✓ Coluna 'created_at' já existe em usuarios"
end

# 3. Adicionar coluna 'modalidade' em alunos
if !column_exists?(conn, 'alunos', 'modalidade')
  puts "  ➕ Adicionando coluna 'modalidade' em alunos..."
  conn.exec("ALTER TABLE alunos ADD COLUMN modalidade VARCHAR(50) DEFAULT 'Jiu Jitsu'")
  puts "     ✅ Coluna 'modalidade' adicionada!"
else
  puts "  ✓ Coluna 'modalidade' já existe em alunos"
end

# 4. Adicionar coluna 'modalidade' em aulas
if !column_exists?(conn, 'aulas', 'modalidade')
  puts "  ➕ Adicionando coluna 'modalidade' em aulas..."
  conn.exec("ALTER TABLE aulas ADD COLUMN modalidade VARCHAR(50) DEFAULT 'Jiu Jitsu'")
  puts "     ✅ Coluna 'modalidade' adicionada!"
else
  puts "  ✓ Coluna 'modalidade' já existe em aulas"
end

# 5. Criar tabela 'notificacoes' se não existir
if !table_exists?(conn, 'notificacoes')
  puts "  ➕ Criando tabela 'notificacoes'..."
  conn.exec(<<~SQL)
    CREATE TABLE notificacoes (
      id SERIAL PRIMARY KEY,
      titulo VARCHAR(255) NOT NULL,
      mensagem TEXT,
      tipo VARCHAR(50) DEFAULT 'info',
      lida BOOLEAN DEFAULT FALSE,
      criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      lida_em TIMESTAMP
    )
  SQL
  puts "     ✅ Tabela 'notificacoes' criada!"
else
  puts "  ✓ Tabela 'notificacoes' já existe"
end

# 6. Marcar admin@jpteam.com como administrador
result = conn.exec_params("SELECT id FROM usuarios WHERE email = $1", ['admin@jpteam.com'])
if result.ntuples > 0
  conn.exec_params("UPDATE usuarios SET admin = TRUE WHERE email = $1", ['admin@jpteam.com'])
  puts "  ✓ Usuário admin@jpteam.com marcado como administrador"
end

conn.close

puts "\n✅ Migração concluída com sucesso!"
puts "   Seus dados foram preservados."
