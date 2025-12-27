class Aula
  def self.todas(pagina = 1, por_pagina = 20)
    pagina = [pagina.to_i, 1].max
    por_pagina = [[por_pagina.to_i, 10].max, 100].min  # Entre 10 e 100
    offset = (pagina - 1) * por_pagina
    
    with_db do |client|
      total = client.exec("SELECT COUNT(*) as count FROM aulas").first['count'].to_i
      aulas = client.exec_params(
        "SELECT * FROM aulas ORDER BY data_aula DESC LIMIT $1 OFFSET $2",
        [por_pagina, offset]
      ).to_a
      
      {
        aulas: aulas,
        pagina_atual: pagina,
        total_paginas: (total.to_f / por_pagina).ceil,
        total: total
      }
    end
  end
  
  # Método legado para compatibilidade
  def self.todas_sem_paginacao
    with_db do |client|
      client.exec("SELECT * FROM aulas ORDER BY data_aula DESC").to_a
    end
  end

  def self.buscar_por_id(id)
    with_db do |client|
      client.exec_params("SELECT * FROM aulas WHERE id = $1", [id]).first
    end
  end

  def self.criar(params)
    result = AulaService.criar_e_inicializar(params)
    result[:aula_id]
  end

  def self.lista_presenca(aula_id)
    with_db do |client|
      client.exec_params(
        "SELECT p.aluno_id AS id, a.nome, p.presente FROM presencas p JOIN alunos a ON p.aluno_id = a.id WHERE p.aula_id = $1 ORDER BY a.nome",
        [aula_id]
      ).to_a
    end
  end

  def self.atualizar_presencas(aula_id, presentes = [])
    AulaService.atualizar_presencas(aula_id, presentes)[:success]
  end

  def self.total_no_mes_atual
    hoje = Date.today
    inicio_mes = Date.new(hoje.year, hoje.month, 1)
    fim_mes = Date.new(hoje.year, hoje.month, -1)
    
    with_db do |client|
      client.exec_params(
        "SELECT COUNT(*) as total FROM aulas
         WHERE data_aula BETWEEN $1 AND $2",
        [inicio_mes.to_s, fim_mes.to_s]
      ).first['total'].to_i
    end
  end
end