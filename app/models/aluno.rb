class Aluno
  extend Validador  # Incluir helpers para reutilizar calcular_idade
  
  # Sanitiza caracteres especiais do LIKE para evitar wildcards maliciosos
  def self.sanitize_like(value)
    value.to_s.gsub(/[%_\\]/) { |c| "\\#{c}" }
  end

  def self.todos
    with_db do |client|
      client.exec("SELECT * FROM alunos WHERE deleted_at IS NULL ORDER BY nome").to_a
    end
  end

  def self.buscar_por_id(id)
    with_db do |client|
      client.exec_params("SELECT * FROM alunos WHERE id = $1 AND deleted_at IS NULL", [id.to_i]).first
    end
  end

  def self.buscar_com_filtros(filtros = {}, pagina = 1, por_pagina = 20)
    pagina = [pagina.to_i, 1].max
    offset = (pagina - 1) * por_pagina
    
    with_db do |client|
      query = "SELECT id, nome, data_nascimento, modalidade, cor_faixa, turma FROM alunos"
      conditions = ["deleted_at IS NULL"]  # Sempre filtrar por soft delete
      params_list = []
      param_count = 1

      if filtros[:busca] && !filtros[:busca].empty?
        conditions << "nome ILIKE $#{param_count}"
        params_list << "%#{sanitize_like(filtros[:busca])}%"
        param_count += 1
      end

      if filtros[:faixa] && !filtros[:faixa].empty?
        conditions << "cor_faixa = $#{param_count}"
        params_list << filtros[:faixa]
        param_count += 1
      end

      if filtros[:turma] && !filtros[:turma].empty?
        conditions << "turma = $#{param_count}"
        params_list << filtros[:turma]
        param_count += 1
      end

      if filtros[:modalidade] && !filtros[:modalidade].empty?
        conditions << "modalidade = $#{param_count}"
        params_list << filtros[:modalidade]
        param_count += 1
      end

      query += " WHERE #{conditions.join(' AND ')}" unless conditions.empty?
      query += " ORDER BY nome ASC"
      
      # Adicionar paginação se solicitado
      if por_pagina > 0
        query += " LIMIT $#{param_count} OFFSET $#{param_count + 1}"
        params_list << por_pagina
        params_list << offset
      end

      result = client.exec_params(query, params_list).to_a
      
      # Calcular idade para cada aluno usando helper compartilhado
      result.each do |aluno|
        data_nasc_str = aluno['data_nascimento']
        if data_nasc_str && !data_nasc_str.empty?
          begin
            data_nasc_obj = Date.parse(data_nasc_str)
            aluno['idade'] = calcular_idade(data_nasc_obj)
          rescue Date::Error
            aluno['idade'] = 'Inválida'
          end
        else
          aluno['idade'] = 'N/A'
        end
      end
      
      # Se paginação estiver ativa, contar total
      if por_pagina > 0
        count_query = "SELECT COUNT(*) AS total FROM alunos"
        count_query += " WHERE #{conditions.join(' AND ')}" unless conditions.empty?
        total = client.exec_params(count_query, params_list[0..-3] || []).first['total'].to_i
        
        return {
          alunos: result, 
          total: total,
          pagina_atual: pagina,
          total_paginas: (total.to_f / por_pagina).ceil
        }
      else
        return result
      end
    end
  end

  def self.total
    with_db do |client|
      result = client.exec("SELECT COUNT(id) AS count FROM alunos WHERE deleted_at IS NULL")
      result.first['count'].to_i
    end
  end

  def self.criar(params)
    with_db do |client|
      client.exec <<~SQL
        SELECT setval(
          pg_get_serial_sequence('alunos', 'id'),
          (SELECT COALESCE(MAX(id), 0) FROM alunos)
        );
      SQL

      bolsista = params['bolsista'] == 'on'

      query = <<~SQL
        INSERT INTO alunos(
          nome, data_nascimento, modalidade, cor_faixa, turma,
          bolsista, saude_problema, saude_medicacao,
          saude_lesao, saude_substancia
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id
      SQL

      params_list = [
        params['nome'].strip,
        params['data_nascimento'].empty? ? nil : params['data_nascimento'],
        params['modalidade'] || 'Jiu Jitsu',
        params['cor_faixa'],
        params['turma'],
        bolsista,
        params['saude_problema'],
        params['saude_medicacao'],
        params['saude_lesao'],
        params['saude_substancia']
      ]

      result = client.exec_params(query, params_list)
      result.first
    end
  end

  def self.atualizar(id, params)
    with_db do |client|
      bolsista = params['bolsista'] == 'on'
      
      query = <<~SQL
        UPDATE alunos SET
          nome = $1,
          data_nascimento = $2,
          modalidade = $3,
          cor_faixa = $4,
          turma = $5,
          bolsista = $6,
          saude_problema = $7,
          saude_medicacao = $8,
          saude_lesao = $9,
          saude_substancia = $10
        WHERE id = $11
        RETURNING id
      SQL
      
      params_list = [
        params['nome'].strip,
        params['data_nascimento'].empty? ? nil : params['data_nascimento'],
        params['modalidade'] || 'Jiu Jitsu',
        params['cor_faixa'],
        params['turma'],
        bolsista,
        params['saude_problema'],
        params['saude_medicacao'],
        params['saude_lesao'],
        params['saude_substancia'],
        id
      ]

      result = client.exec_params(query, params_list)
      result.first
    end
  end

  # Soft delete - marca o aluno como excluído sem remover do banco
  def self.excluir(id)
    with_db do |client|
      client.exec_params(
        "UPDATE alunos SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1 AND deleted_at IS NULL RETURNING id",
        [id]
      ).first
    end
  end
  
  # Hard delete - remove permanentemente (usar com cuidado)
  def self.excluir_permanente(id)
    with_db do |client|
      client.exec_params("DELETE FROM alunos WHERE id = $1 RETURNING id", [id]).first
    end
  end
  
  # Restaurar aluno excluído
  def self.restaurar(id)
    with_db do |client|
      client.exec_params(
        "UPDATE alunos SET deleted_at = NULL, updated_at = NOW() WHERE id = $1 RETURNING id",
        [id]
      ).first
    end
  end
  
  # Buscar alunos excluídos (para admin)
  def self.buscar_excluidos
    with_db do |client|
      client.exec("SELECT * FROM alunos WHERE deleted_at IS NOT NULL ORDER BY deleted_at DESC").to_a
    end
  end

  def self.registrar_graduacao(aluno_id, faixa, data_graduacao)
    with_db do |client|
      # Usar transação para garantir atomicidade
      client.exec("BEGIN")
      begin
        # Registrar graduação
        client.exec_params(
          "INSERT INTO graduacoes(aluno_id, faixa, data_graduacao) VALUES ($1, $2, $3) RETURNING id",
          [aluno_id, faixa, data_graduacao]
        )
        
        # Atualizar faixa atual do aluno
        client.exec_params(
          "UPDATE alunos SET cor_faixa = $1, updated_at = NOW() WHERE id = $2",
          [faixa, aluno_id]
        )
        
        client.exec("COMMIT")
      rescue => e
        client.exec("ROLLBACK")
        raise e
      end
    end
  end

  def self.obter_graduacoes(aluno_id)
    with_db do |client|
      client.exec_params(
        "SELECT * FROM graduacoes WHERE aluno_id = $1 ORDER BY data_graduacao DESC",
        [aluno_id]
      ).to_a
    end
  end

  def self.obter_presencas(aluno_id)
    with_db do |client|
      # Buscar turma do aluno para contar apenas aulas relevantes
      aluno = client.exec_params("SELECT turma, modalidade FROM alunos WHERE id = $1", [aluno_id]).first
      return { total_aulas: 0, presencas: 0, faltas: 0 } unless aluno
      
      turma = aluno['turma']
      modalidade = aluno['modalidade']
      
      # Contar aulas da turma do aluno (ou todas se não tiver turma definida)
      if turma && !turma.empty?
        total_aulas = client.exec_params(
          "SELECT COUNT(id) as count FROM aulas WHERE turma = $1",
          [turma]
        ).first['count'].to_i
      else
        total_aulas = client.exec("SELECT COUNT(id) as count FROM aulas").first['count'].to_i
      end
      
      presencas = client.exec_params(
        "SELECT COUNT(id) as count FROM presencas WHERE aluno_id = $1 AND presente = TRUE",
        [aluno_id]
      ).first['count'].to_i
      
      {
        total_aulas: total_aulas,
        presencas: presencas,
        faltas: [total_aulas - presencas, 0].max
      }
    end
  end

  def self.aniversariantes_do_mes
    mes_atual = Date.today.month
    with_db do |client|
      client.exec_params(
        "SELECT id, nome, data_nascimento FROM alunos 
         WHERE EXTRACT(MONTH FROM data_nascimento) = $1
         AND deleted_at IS NULL
         ORDER BY EXTRACT(DAY FROM data_nascimento)",
        [mes_atual]
      ).to_a
    end
  end

  def self.relatorio_frequencia(inicio_periodo = nil, fim_periodo = nil)
    hoje = Date.today
    inicio_periodo ||= Date.new(hoje.year, hoje.month, 1)
    fim_periodo ||= hoje
    
    with_db do |client|
      # Query otimizada: busca tudo de uma vez usando LEFT JOIN e agregação
      # Evita N+1 queries (antes fazia N*M queries para N alunos e M aulas)
      query = <<~SQL
        WITH aulas_periodo AS (
          SELECT id FROM aulas 
          WHERE data_aula BETWEEN $1 AND $2
        ),
        total_aulas AS (
          SELECT COUNT(*) as count FROM aulas_periodo
        ),
        presencas_por_aluno AS (
          SELECT 
            al.id as aluno_id,
            al.nome,
            COUNT(CASE WHEN p.presente = TRUE THEN 1 END) as presencas,
            COUNT(CASE WHEN p.presente = FALSE OR p.presente IS NULL THEN 1 END) as faltas
          FROM alunos al
          LEFT JOIN presencas p ON al.id = p.aluno_id 
            AND p.aula_id IN (SELECT id FROM aulas_periodo)
          GROUP BY al.id, al.nome
          ORDER BY al.nome
        )
        SELECT 
          ppa.aluno_id,
          ppa.nome,
          ppa.presencas,
          ppa.faltas,
          ta.count as total_aulas,
          CASE 
            WHEN ta.count = 0 THEN 0 
            ELSE ROUND((ppa.presencas::numeric / ta.count) * 100, 2) 
          END as taxa_frequencia
        FROM presencas_por_aluno ppa
        CROSS JOIN total_aulas ta
      SQL
      
      result = client.exec_params(query, [inicio_periodo.to_s, fim_periodo.to_s]).to_a
      
      # Converter para o formato esperado
      result.map do |r|
        {
          aluno_id: r['aluno_id'],
          nome: r['nome'],
          presencas: r['presencas'].to_i,
          faltas: r['faltas'].to_i,
          total_aulas: r['total_aulas'].to_i,
          taxa_frequencia: r['taxa_frequencia'].to_f
        }
      end
    end
  end
end