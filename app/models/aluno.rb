class Aluno
  def self.todos
    with_db do |client|
      client.exec("SELECT * FROM alunos ORDER BY nome").to_a
    end
  end

  def self.buscar_por_id(id)
    with_db do |client|
      client.exec_params("SELECT * FROM alunos WHERE id = $1", [id]).first
    end
  end

  def self.buscar_com_filtros(filtros = {}, pagina = 1, por_pagina = 20)
    pagina = [pagina.to_i, 1].max
    offset = (pagina - 1) * por_pagina
    
    with_db do |client|
      query = "SELECT id, nome, data_nascimento, modalidade, cor_faixa, turma FROM alunos"
      conditions = []
      params_list = []
      param_count = 1

      if filtros[:busca] && !filtros[:busca].empty?
        conditions << "nome ILIKE $#{param_count}"
        params_list << "%#{filtros[:busca]}%"
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
      
      # Calcular idade para cada aluno
      result.each do |aluno|
        hoje = Date.today
        data_nasc_str = aluno['data_nascimento']
        if data_nasc_str && !data_nasc_str.empty?
          begin
            data_nasc_obj = Date.parse(data_nasc_str)
            idade = hoje.year - data_nasc_obj.year
            idade -= 1 if hoje < Date.new(hoje.year, data_nasc_obj.month, data_nasc_obj.day)
            aluno['idade'] = idade
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
      result = client.exec("SELECT COUNT(id) AS count FROM alunos")
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

  def self.excluir(id)
    with_db do |client|
      client.exec_params("DELETE FROM alunos WHERE id = $1 RETURNING id", [id]).first
    end
  end

  def self.registrar_graduacao(aluno_id, faixa, data_graduacao)
    with_db do |client|
      # Registrar graduação
      client.exec_params(
        "INSERT INTO graduacoes(aluno_id, faixa, data_graduacao) VALUES ($1, $2, $3) RETURNING id",
        [aluno_id, faixa, data_graduacao]
      )
      
      # Atualizar faixa atual do aluno
      client.exec_params(
        "UPDATE alunos SET cor_faixa = $1 WHERE id = $2",
        [faixa, aluno_id]
      )
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
      total_aulas = client.exec("SELECT COUNT(id) as count FROM aulas").first['count'].to_i
      presencas = client.exec_params(
        "SELECT COUNT(id) as count FROM presencas WHERE aluno_id = $1 AND presente = TRUE",
        [aluno_id]
      ).first['count'].to_i
      
      {
        total_aulas: total_aulas,
        presencas: presencas,
        faltas: total_aulas - presencas
      }
    end
  end

  def self.aniversariantes_do_mes
    mes_atual = Date.today.month
    with_db do |client|
      client.exec_params(
        "SELECT id, nome, data_nascimento FROM alunos 
         WHERE EXTRACT(MONTH FROM data_nascimento) = $1
         ORDER BY EXTRACT(DAY FROM data_nascimento)",
        [mes_atual]
      ).to_a
    end
  end

  def self.relatorio_frequencia(inicio_periodo = nil, fim_periodo = nil)
    inicio_periodo ||= Date.today.beginning_of_month
    fim_periodo ||= Date.today
    
    with_db do |client|
      # Buscar todos os alunos ativos
      alunos = client.exec("SELECT id, nome FROM alunos ORDER BY nome").to_a
      
      # Buscar aulas no período
      aulas = client.exec_params(
        "SELECT id, data_aula FROM aulas WHERE data_aula BETWEEN $1 AND $2 ORDER BY data_aula",
        [inicio_periodo.to_s, fim_periodo.to_s]
      ).to_a
      
      # Para cada aluno, verificar a presença em cada aula
      resultados = []
      
      alunos.each do |aluno|
        presencas = 0
        faltas = 0
        
        aulas.each do |aula|
          presente = client.exec_params(
            "SELECT presente FROM presencas WHERE aluno_id = $1 AND aula_id = $2",
            [aluno['id'], aula['id']]
          ).first
          
          if presente && presente['presente'] == 't'
            presencas += 1
          else
            faltas += 1
          end
        end
        
        # Calcular a taxa de frequência
        taxa_frequencia = aulas.empty? ? 0 : (presencas.to_f / aulas.size * 100).round(2)
        
        resultados << {
          aluno_id: aluno['id'],
          nome: aluno['nome'],
          presencas: presencas,
          faltas: faltas,
          total_aulas: aulas.size,
          taxa_frequencia: taxa_frequencia
        }
      end

      resultados
    end
  end
end