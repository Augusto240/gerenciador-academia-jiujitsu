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
      count = 0
      assinaturas = client.exec("SELECT id FROM assinaturas WHERE status = 'ativa'").to_a
      
      assinaturas.each do |assinatura|
        status_info = verificar_status(assinatura['id'])
        count += 1 if status_info[:status] == status_texto
      end

      count
    end
  end
end