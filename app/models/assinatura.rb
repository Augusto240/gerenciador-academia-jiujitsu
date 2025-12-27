class Assinatura
  def self.buscar_ativa(aluno_id)
    with_db do |client|
      client.exec_params(
        "SELECT * FROM assinaturas WHERE aluno_id = $1 AND status = 'ativa'",
        [aluno_id]
      ).first
    end
  end

  def self.criar(aluno_id, valor_mensalidade = 70.00)
    with_db do |client|
      client.exec_params(
        "INSERT INTO assinaturas(aluno_id, plano_id, valor_mensalidade, status)
         VALUES ($1, 1, $2, 'ativa') RETURNING id",
        [aluno_id, valor_mensalidade]
      ).first
    end
  end

  def self.historico_pagamentos(assinatura_id)
    with_db do |client|
      client.exec_params(
        "SELECT * FROM pagamentos WHERE assinatura_id = $1 ORDER BY data_pagamento DESC",
        [assinatura_id]
      ).to_a
    end
  end

  def self.registrar_pagamento(assinatura_id, valor_pago, data_pagamento)
    with_db do |client|
      client.exec_params(
        "INSERT INTO pagamentos(assinatura_id, valor_pago, data_pagamento) VALUES ($1, $2, $3) RETURNING id",
        [assinatura_id, valor_pago, data_pagamento]
      ).first
    end
  end

  def self.verificar_status(assinatura_id)
    with_db do |client|
      assinatura = client.exec_params(
        "SELECT * FROM assinaturas WHERE id = $1", 
        [assinatura_id]
      ).first

      return { status: "Inativa", cor: "status-inativo" } unless assinatura

      ultimo_pag = client.exec_params(
        "SELECT data_pagamento FROM pagamentos WHERE assinatura_id = $1 ORDER BY data_pagamento DESC LIMIT 1",
        [assinatura_id]
      ).first

      if ultimo_pag
        vencimento = Date.parse(ultimo_pag['data_pagamento']) + 30
        if Date.today > vencimento
          { status: "Atrasado", cor: "status-atrasado" }
        else
          { status: "Em Dia", cor: "status-em-dia" }
        end
      else
        { status: "Pendente", cor: "status-pendente" }
      end
    end
  end
  
  def self.contar_por_status(status_texto)
    with_db do |client|
      # Query única otimizada - evita N+1
      query = <<~SQL
        SELECT COUNT(*) as count
        FROM assinaturas a
        LEFT JOIN (
          SELECT assinatura_id, MAX(data_pagamento) as ultimo_pagamento
          FROM pagamentos
          GROUP BY assinatura_id
        ) p ON a.id = p.assinatura_id
        WHERE a.status = 'ativa'
        AND CASE 
          WHEN $1 = 'Atrasado' THEN 
            p.ultimo_pagamento IS NOT NULL AND (p.ultimo_pagamento + INTERVAL '30 days') < CURRENT_DATE
          WHEN $1 = 'Em Dia' THEN 
            p.ultimo_pagamento IS NOT NULL AND (p.ultimo_pagamento + INTERVAL '30 days') >= CURRENT_DATE
          WHEN $1 = 'Pendente' THEN 
            p.ultimo_pagamento IS NULL
          ELSE FALSE
        END
      SQL
      client.exec_params(query, [status_texto]).first['count'].to_i
    end
  end

  def self.relatorio_mensalidades
    with_db do |client|
      # Query única otimizada - evita N+1
      query = <<~SQL
        SELECT 
          a.id as assinatura_id, 
          a.valor_mensalidade, 
          a.status,
          al.id as aluno_id, 
          al.nome, 
          al.modalidade,
          p.ultimo_pagamento,
          CASE 
            WHEN p.ultimo_pagamento IS NULL THEN 'Pendente'
            WHEN (p.ultimo_pagamento + INTERVAL '30 days') < CURRENT_DATE THEN 'Atrasado'
            ELSE 'Em Dia'
          END as status_pagamento,
          CASE 
            WHEN p.ultimo_pagamento IS NULL THEN 'status-pendente'
            WHEN (p.ultimo_pagamento + INTERVAL '30 days') < CURRENT_DATE THEN 'status-atrasado'
            ELSE 'status-em-dia'
          END as cor_status,
          CASE 
            WHEN p.ultimo_pagamento IS NULL THEN 0
            WHEN (p.ultimo_pagamento + INTERVAL '30 days') < CURRENT_DATE THEN 
              EXTRACT(DAY FROM CURRENT_DATE - (p.ultimo_pagamento + INTERVAL '30 days'))::int
            ELSE 0
          END as dias_atraso
        FROM assinaturas a
        JOIN alunos al ON a.aluno_id = al.id
        LEFT JOIN (
          SELECT assinatura_id, MAX(data_pagamento) as ultimo_pagamento
          FROM pagamentos
          GROUP BY assinatura_id
        ) p ON a.id = p.assinatura_id
        WHERE a.status = 'ativa' AND al.deleted_at IS NULL
        ORDER BY al.nome
      SQL
      
      client.exec(query).to_a.map do |row|
        ultimo_pag_str = row['ultimo_pagamento'] ? 
          Date.parse(row['ultimo_pagamento']).strftime('%d/%m/%Y') : 
          'Nunca'
        
        {
          aluno_id: row['aluno_id'],
          nome: row['nome'],
          modalidade: row['modalidade'] || 'Jiu Jitsu',
          valor_mensalidade: row['valor_mensalidade'].to_f,
          status: row['status_pagamento'],
          cor_status: row['cor_status'],
          ultimo_pagamento: ultimo_pag_str,
          dias_atraso: [row['dias_atraso'].to_i, 0].max
        }
      end
    end
  end
end