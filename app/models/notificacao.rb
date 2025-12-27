class Notificacao
  def self.todas
    with_db do |client|
      client.exec("SELECT * FROM notificacoes ORDER BY criado_em DESC").to_a
    end
  end
  
  def self.pendentes
    with_db do |client|
      client.exec("SELECT * FROM notificacoes WHERE lida = FALSE ORDER BY criado_em DESC").to_a
    end
  end
  
  def self.criar(titulo, mensagem, tipo = 'info')
    with_db do |client|
      # Usar INSERT ON CONFLICT para evitar race condition e duplicatas
      client.exec_params(
        "INSERT INTO notificacoes(titulo, mensagem, tipo, lida, criado_em) 
         VALUES ($1, $2, $3, FALSE, NOW())
         ON CONFLICT DO NOTHING
         RETURNING id",
        [titulo, mensagem, tipo]
      ).first
    end
  end
  
  def self.marcar_como_lida(id)
    with_db do |client|
      client.exec_params(
        "UPDATE notificacoes SET lida = TRUE, lida_em = NOW() WHERE id = $1",
        [id]
      )
    end
  end
  
  def self.gerar_notificacoes_automaticas
    # Verificar mensalidades atrasadas - Query única otimizada (sem N+1)
    with_db do |client|
      # Buscar todas as assinaturas atrasadas de uma vez usando subquery
      atrasados = client.exec(<<~SQL).to_a
        SELECT a.id, al.nome
        FROM assinaturas a
        JOIN alunos al ON a.aluno_id = al.id
        LEFT JOIN (
          SELECT assinatura_id, MAX(data_pagamento) as ultimo_pagamento
          FROM pagamentos
          GROUP BY assinatura_id
        ) p ON a.id = p.assinatura_id
        WHERE a.status = 'ativa'
          AND al.deleted_at IS NULL
          AND p.ultimo_pagamento IS NOT NULL
          AND (p.ultimo_pagamento + INTERVAL '30 days') < CURRENT_DATE
      SQL
      
      atrasados.each do |assinatura|
        titulo = "Mensalidade atrasada"
        mensagem = "A mensalidade do aluno #{assinatura['nome']} está atrasada."
        
        # Usar INSERT com ON CONFLICT para evitar duplicatas de forma atômica
        client.exec_params(
          "INSERT INTO notificacoes(titulo, mensagem, tipo, lida, criado_em)
           SELECT $1, $2, 'warning', FALSE, NOW()
           WHERE NOT EXISTS (
             SELECT 1 FROM notificacoes WHERE mensagem = $2 AND lida = FALSE
           )",
          [titulo, mensagem]
        )
      end
    end
    
    # Verificar aniversariantes do dia
    hoje = Date.today
    with_db do |client|
      aniversariantes = client.exec_params(
        "SELECT id, nome FROM alunos 
         WHERE EXTRACT(MONTH FROM data_nascimento) = $1 
         AND EXTRACT(DAY FROM data_nascimento) = $2",
        [hoje.month, hoje.day]
      ).to_a
      
      aniversariantes.each do |aluno|
        titulo = "Aniversário hoje!"
        mensagem = "Hoje é aniversário de #{aluno['nome']}."
        
        # Usar INSERT com ON CONFLICT para evitar duplicatas de forma atômica
        client.exec_params(
          "INSERT INTO notificacoes(titulo, mensagem, tipo, lida, criado_em)
           SELECT $1, $2, 'info', FALSE, NOW()
           WHERE NOT EXISTS (
             SELECT 1 FROM notificacoes WHERE mensagem = $2 AND lida = FALSE
           )",
          [titulo, mensagem]
        )
      end
    end
  end
end