#!/usr/bin/env ruby
# Migração: Adicionar índice parcial para alunos ativos (soft delete)
# Este índice otimiza consultas que filtram por deleted_at IS NULL

require_relative '../config/database'

def run_migration
  with_db do |client|
    puts "Verificando índice idx_alunos_active..."
    
    # Verificar se o índice já existe
    result = client.exec(
      "SELECT indexname FROM pg_indexes WHERE tablename = 'alunos' AND indexname = 'idx_alunos_active'"
    )
    
    if result.ntuples > 0
      puts "Índice idx_alunos_active já existe."
    else
      puts "Criando índice parcial idx_alunos_active..."
      
      # Criar índice parcial para alunos ativos (não excluídos)
      # Otimiza queries que usam WHERE deleted_at IS NULL
      client.exec(
        "CREATE INDEX idx_alunos_active ON alunos(nome, turma, modalidade) WHERE deleted_at IS NULL"
      )
      
      puts "✅ Índice idx_alunos_active criado com sucesso!"
    end
    
    # Criar índice para aulas por data
    result = client.exec(
      "SELECT indexname FROM pg_indexes WHERE tablename = 'aulas' AND indexname = 'idx_aulas_data'"
    )
    
    if result.ntuples == 0
      puts "Criando índice idx_aulas_data..."
      client.exec("CREATE INDEX idx_aulas_data ON aulas(data_aula DESC)")
      puts "✅ Índice idx_aulas_data criado com sucesso!"
    else
      puts "Índice idx_aulas_data já existe."
    end
    
    # Criar índice para presenças por aula
    result = client.exec(
      "SELECT indexname FROM pg_indexes WHERE tablename = 'presencas' AND indexname = 'idx_presencas_aula'"
    )
    
    if result.ntuples == 0
      puts "Criando índice idx_presencas_aula..."
      client.exec("CREATE INDEX idx_presencas_aula ON presencas(aula_id, presente)")
      puts "✅ Índice idx_presencas_aula criado com sucesso!"
    else
      puts "Índice idx_presencas_aula já existe."
    end
    
    puts "\n✅ Migração concluída com sucesso!"
  end
rescue PG::Error => e
  puts "❌ Erro ao executar migração: #{e.message}"
  exit 1
end

if __FILE__ == $0
  run_migration
end
