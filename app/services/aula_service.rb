module AulaService
  def self.criar_e_inicializar(params)
    result = { success: false, message: "", aula_id: nil }
    
    begin
      with_db do |client|
        # Iniciar transação para garantir atomicidade
        client.exec("BEGIN")
        
        begin
          modalidade = params['modalidade'] || 'Jiu Jitsu'
          turma_aula = params['turma'].to_s.empty? ? nil : params['turma']
          todas_turmas = params['todas_turmas'] == 'on'

          # Para Muay Thai, a turma é sempre "Muay Thai"
          if modalidade == 'Muay Thai'
            turma_aula = 'Muay Thai'
          end

          insert_result = client.exec_params(
            "INSERT INTO aulas (data_aula, modalidade, turma, descricao) VALUES ($1, $2, $3, $4) RETURNING id",
            [params['data_aula'], modalidade, turma_aula, params['descricao']]
          ).first
          aula_id = insert_result['id']

          # Selecionar alunos para a lista de presença baseado na modalidade
          alunos_q = if modalidade == 'Muay Thai'
            # Para Muay Thai, pegar todos os alunos dessa modalidade
            client.exec_params("SELECT id FROM alunos WHERE modalidade = $1 AND deleted_at IS NULL", [modalidade])
          elsif todas_turmas
            # Para Jiu Jitsu com todas as turmas
            client.exec_params("SELECT id FROM alunos WHERE modalidade = $1 AND deleted_at IS NULL", ['Jiu Jitsu'])
          elsif turma_aula
            # Para uma turma específica de Jiu Jitsu
            client.exec_params("SELECT id FROM alunos WHERE turma = $1 AND modalidade = $2 AND deleted_at IS NULL", [turma_aula, 'Jiu Jitsu'])
          else
            # Fallback: todos os alunos de Jiu Jitsu
            client.exec_params("SELECT id FROM alunos WHERE modalidade = $1 AND deleted_at IS NULL", ['Jiu Jitsu'])
          end

          # Inicializar presenças em massa com batch insert (otimizado)
          alunos_ids = alunos_q.map { |a| a['id'] }
          
          if alunos_ids.any?
            # Construir batch insert para melhor performance
            values = alunos_ids.map.with_index { |id, i| "($1, $#{i + 2}, FALSE)" }.join(", ")
            params_list = [aula_id] + alunos_ids
            
            client.exec_params(
              "INSERT INTO presencas (aula_id, aluno_id, presente) VALUES #{values} ON CONFLICT (aluno_id, aula_id) DO NOTHING",
              params_list
            )
          end
          
          # Commit da transação se tudo ocorreu bem
          client.exec("COMMIT")
          
          result[:success] = true
          result[:message] = "Aula criada com sucesso!"
          result[:aula_id] = aula_id
        rescue => e
          # Rollback em caso de erro
          client.exec("ROLLBACK")
          raise e
        end
      end
    rescue PG::Error => e
      result[:message] = "Erro de banco de dados: #{e.message}"
    rescue => e
      result[:message] = "Erro inesperado: #{e.message}"
    end
    
    result
  end
  
  def self.atualizar_presencas(aula_id, presentes = [])
    result = { success: false, message: "", presencas_atualizadas: 0 }
    
    begin
      with_db do |client|
        # Marcar todos como ausentes primeiro
        client.exec_params("UPDATE presencas SET presente = FALSE WHERE aula_id = $1", [aula_id])
        
        # Contar quantos alunos serão marcados como presentes
        count = presentes.length
        
        # Marcar os presentes em batch (otimizado)
        if presentes.any?
          # Converter para inteiros e construir lista para IN clause
          alunos_ids = presentes.map(&:to_i)
          placeholders = alunos_ids.map.with_index { |_, i| "$#{i + 2}" }.join(", ")
          
          client.exec_params(
            "UPDATE presencas SET presente = TRUE WHERE aula_id = $1 AND aluno_id IN (#{placeholders})",
            [aula_id] + alunos_ids
          )
        end
        
        result[:success] = true
        result[:message] = "Lista de presença atualizada com sucesso!"
        result[:presencas_atualizadas] = count
      end
    rescue => e
      result[:message] = "Erro ao atualizar presenças: #{e.message}"
    end
    
    result
  end
end