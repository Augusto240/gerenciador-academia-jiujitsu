module AulaService
  def self.criar_e_inicializar(params)
    result = { success: false, message: "", aula_id: nil }
    
    begin
      with_db do |client|
        turma_aula = params['turma'].empty? ? nil : params['turma']
        todas_turmas = params['todas_turmas'] == 'on'

        insert_result = client.exec_params(
          "INSERT INTO aulas (data_aula, turma, descricao) VALUES ($1, $2, $3) RETURNING id",
          [params['data_aula'], turma_aula, params['descricao']]
        ).first
        aula_id = insert_result['id']

        # Selecionar alunos para a lista de presença
        alunos_q = if todas_turmas
          client.exec("SELECT id FROM alunos")
        elsif turma_aula
          client.exec_params("SELECT id FROM alunos WHERE turma = $1", [turma_aula])
        else
          client.exec("SELECT id FROM alunos")
        end

        # Inicializar presenças em massa
        alunos_q.each do |a|
          client.exec_params(
            "INSERT INTO presencas (aula_id, aluno_id, presente) VALUES ($1, $2, FALSE) ON CONFLICT (aluno_id, aula_id) DO NOTHING",
            [aula_id, a['id']]
          )
        end
        
        result[:success] = true
        result[:message] = "Aula criada com sucesso!"
        result[:aula_id] = aula_id
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
        
        # Marcar os presentes
        presentes.each do |aluno_id|
          client.exec_params(
            "UPDATE presencas SET presente = TRUE WHERE aula_id = $1 AND aluno_id = $2",
            [aula_id, aluno_id]
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