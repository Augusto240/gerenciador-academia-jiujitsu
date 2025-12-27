module PagamentoService
  def self.registrar_pagamento(assinatura_id, aluno_id, valor_pago, data_pagamento)
    result = { success: false, message: "", payment_id: nil }

    begin
      # Validações básicas (além das feitas no controlador)
      if valor_pago.to_f <= 0
        result[:message] = "Valor do pagamento deve ser positivo"
        return result
      end

      # Registrar pagamento com transação para garantir atomicidade
      with_db do |client|
        client.exec("BEGIN")
        
        begin
          payment_record = client.exec_params(
            "INSERT INTO pagamentos(assinatura_id, valor_pago, data_pagamento) 
             VALUES ($1, $2, $3) RETURNING id",
            [assinatura_id, valor_pago, data_pagamento]
          ).first

          # Atualizar status da assinatura se necessário
          client.exec_params(
            "UPDATE assinaturas SET status = 'ativa' WHERE id = $1 AND status != 'ativa'",
            [assinatura_id]
          )

          client.exec("COMMIT")
          
          result[:success] = true
          result[:message] = "Pagamento registrado com sucesso!"
          result[:payment_id] = payment_record['id']
        rescue => e
          client.exec("ROLLBACK")
          raise e
        end
      end
    rescue PG::Error => e
      result[:message] = "Erro ao registrar pagamento: #{e.message}"
    rescue => e
      result[:message] = "Erro inesperado: #{e.message}"
    end

    result
  end
end