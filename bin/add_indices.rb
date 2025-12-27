#!/usr/bin/env ruby
# Script para adicionar índices de performance ao banco de dados
# Uso: ruby bin/add_indices.rb

require_relative '../config/database'

puts "Adicionando índices de performance ao banco de dados..."

indices = [
  # Índices para alunos
  { name: 'idx_alunos_nome', sql: 'CREATE INDEX IF NOT EXISTS idx_alunos_nome ON alunos(nome)' },
  { name: 'idx_alunos_modalidade', sql: 'CREATE INDEX IF NOT EXISTS idx_alunos_modalidade ON alunos(modalidade)' },
  { name: 'idx_alunos_turma', sql: 'CREATE INDEX IF NOT EXISTS idx_alunos_turma ON alunos(turma)' },
  { name: 'idx_alunos_data_nascimento', sql: 'CREATE INDEX IF NOT EXISTS idx_alunos_data_nascimento ON alunos(data_nascimento)' },
  
  # Índices para assinaturas
  { name: 'idx_assinaturas_aluno_id', sql: 'CREATE INDEX IF NOT EXISTS idx_assinaturas_aluno_id ON assinaturas(aluno_id)' },
  { name: 'idx_assinaturas_status', sql: 'CREATE INDEX IF NOT EXISTS idx_assinaturas_status ON assinaturas(status)' },
  
  # Índices para pagamentos
  { name: 'idx_pagamentos_assinatura_id', sql: 'CREATE INDEX IF NOT EXISTS idx_pagamentos_assinatura_id ON pagamentos(assinatura_id)' },
  { name: 'idx_pagamentos_data', sql: 'CREATE INDEX IF NOT EXISTS idx_pagamentos_data ON pagamentos(data_pagamento DESC)' },
  
  # Índices para aulas
  { name: 'idx_aulas_data', sql: 'CREATE INDEX IF NOT EXISTS idx_aulas_data ON aulas(data_aula DESC)' },
  { name: 'idx_aulas_modalidade', sql: 'CREATE INDEX IF NOT EXISTS idx_aulas_modalidade ON aulas(modalidade)' },
  { name: 'idx_aulas_turma', sql: 'CREATE INDEX IF NOT EXISTS idx_aulas_turma ON aulas(turma)' },
  
  # Índices para presenças
  { name: 'idx_presencas_aula_id', sql: 'CREATE INDEX IF NOT EXISTS idx_presencas_aula_id ON presencas(aula_id)' },
  { name: 'idx_presencas_aluno_id', sql: 'CREATE INDEX IF NOT EXISTS idx_presencas_aluno_id ON presencas(aluno_id)' },
  
  # Índices para graduações
  { name: 'idx_graduacoes_aluno_id', sql: 'CREATE INDEX IF NOT EXISTS idx_graduacoes_aluno_id ON graduacoes(aluno_id)' },
  { name: 'idx_graduacoes_data', sql: 'CREATE INDEX IF NOT EXISTS idx_graduacoes_data ON graduacoes(data_graduacao DESC)' },
  
  # Índices para notificações
  { name: 'idx_notificacoes_criado_em', sql: 'CREATE INDEX IF NOT EXISTS idx_notificacoes_criado_em ON notificacoes(criado_em DESC)' }
]

with_db do |client|
  indices.each do |idx|
    begin
      client.exec(idx[:sql])
      puts "✅ #{idx[:name]}"
    rescue PG::Error => e
      puts "⚠️  #{idx[:name]}: #{e.message}"
    end
  end
end

puts "\nMigração de índices concluída!"
