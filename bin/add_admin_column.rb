#!/usr/bin/env ruby
# Script para adicionar coluna admin na tabela usuarios
# Execute com: docker compose exec app ruby bin/add_admin_column.rb

require_relative '../config/database'

puts "Adicionando coluna 'admin' à tabela usuarios..."

begin
  with_db do |client|
    # Verificar se a coluna já existe
    result = client.exec(<<~SQL)
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'usuarios' AND column_name = 'admin'
    SQL

    if result.ntuples > 0
      puts "A coluna 'admin' já existe na tabela usuarios."
    else
      client.exec(<<~SQL)
        ALTER TABLE usuarios 
        ADD COLUMN admin BOOLEAN DEFAULT FALSE
      SQL
      puts "Coluna 'admin' adicionada com sucesso!"
    end

    # Marcar o usuário admin@jpteam.com como admin
    client.exec_params(<<~SQL, ['admin@jpteam.com'])
      UPDATE usuarios SET admin = TRUE WHERE email = $1
    SQL
    puts "Usuário admin@jpteam.com marcado como administrador."
  end
rescue => e
  puts "Erro ao executar migração: #{e.message}"
  exit 1
end

puts "Migração concluída!"
