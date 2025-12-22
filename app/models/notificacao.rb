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
      client.exec_params(
        "INSERT INTO notificacoes(titulo, mensagem, tipo, lida, criado_em) 
         VALUES ($1, $2, $3, FALSE, NOW()) RETURNING id",
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
    # Verificar mensalidades atrasadas
    with_db do |client|
      assinaturas = client.exec("SELECT a.id, al.nome FROM assinaturas a JOIN alunos al ON a.aluno_id = al.id WHERE a.status = 'ativa'").to_a
      
      assinaturas.each do |assinatura|
        status_info = Assinatura.verificar_status(assinatura['id'])
        
        if status_info[:status] == "Atrasado"
          titulo = "Mensalidade atrasada"
          mensagem = "A mensalidade do aluno #{assinatura['nome']} está atrasada."
          
          # Verificar se já existe notificação similar não lida
          notificacoes_existentes = client.exec_params(
            "SELECT id FROM notificacoes WHERE mensagem = $1 AND lida = FALSE",
            [mensagem]
          ).to_a
          
          if notificacoes_existentes.empty?
            criar(titulo, mensagem, 'warning')
          end
        end
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
        
        # Verificar se já existe notificação similar não lida
        notificacoes_existentes = client.exec_params(
          "SELECT id FROM notificacoes WHERE mensagem = $1 AND lida = FALSE",
          [mensagem]
        ).to_a
        
        if notificacoes_existentes.empty?
          criar(titulo, mensagem, 'info')
        end
      end
    end
  end
end