#!/usr/bin/env ruby
# Script para adicionar a coluna modalidade na tabela aulas
# Execute com: ruby bin/add_modalidade_aulas.rb
# Ou via docker: docker compose exec app ruby bin/add_modalidade_aulas.rb

require_relative '../config/database'

puts "Adicionando coluna 'modalidade' à tabela aulas..."

begin
  with_db do |client|
    # Verificar se a coluna já existe
    result = client.exec(<<~SQL)
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'aulas' AND column_name = 'modalidade'
    SQL

    if result.ntuples > 0
      puts "A coluna 'modalidade' já existe na tabela aulas. Nenhuma alteração necessária."
    else
      # Adicionar a coluna
      client.exec(<<~SQL)
        ALTER TABLE aulas 
        ADD COLUMN modalidade VARCHAR(50) DEFAULT 'Jiu Jitsu'
      SQL
      
      puts "Coluna 'modalidade' adicionada com sucesso na tabela aulas!"
      puts "Todas as aulas existentes foram definidas como 'Jiu Jitsu' por padrão."
    end
  end
rescue => e
  puts "Erro ao executar migração: #{e.message}"
  exit 1
end

puts "Migração concluída!"
