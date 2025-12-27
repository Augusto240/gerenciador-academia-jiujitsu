#!/usr/bin/env ruby
# Script para adicionar soft delete à tabela de alunos
# Uso: ruby bin/add_soft_delete.rb

require_relative '../config/database'

puts "Adicionando colunas de soft delete à tabela alunos..."

with_db do |client|
  begin
    # Verificar se as colunas já existem
    result = client.exec("SELECT column_name FROM information_schema.columns WHERE table_name = 'alunos' AND column_name = 'deleted_at'")
    
    if result.ntuples == 0
      # Adicionar colunas
      client.exec("ALTER TABLE alunos ADD COLUMN deleted_at TIMESTAMP DEFAULT NULL")
      client.exec("ALTER TABLE alunos ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
      client.exec("ALTER TABLE alunos ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
      
      # Criar índice para deleted_at
      client.exec("CREATE INDEX idx_alunos_deleted_at ON alunos(deleted_at) WHERE deleted_at IS NULL")
      
      puts "✅ Colunas adicionadas com sucesso!"
    else
      puts "⚠️  Colunas já existem, nada a fazer."
    end
  rescue PG::Error => e
    puts "❌ Erro: #{e.message}"
    exit 1
  end
end

puts "Migração concluída!"
