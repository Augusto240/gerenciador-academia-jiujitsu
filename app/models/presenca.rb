class Presenca
  def self.total_no_mes_atual
    hoje = Date.today
    inicio_mes = Date.new(hoje.year, hoje.month, 1)
    fim_mes = Date.new(hoje.year, hoje.month, -1)
    
    with_db do |client|
      client.exec_params(
        "SELECT COUNT(*) as total FROM presencas p
         JOIN aulas a ON p.aula_id = a.id
         WHERE a.data_aula BETWEEN $1 AND $2 AND p.presente = TRUE",
        [inicio_mes.to_s, fim_mes.to_s]
      ).first['total'].to_i
    end
  end

  def self.historico_ultimos_meses(quantidade = 6)
    with_db do |client|
      meses = []
      dados = []
      
      quantidade.downto(1) do |i|
        data = Date.today << i  # Recua i meses
        inicio_mes = Date.new(data.year, data.month, 1).to_s
        fim_mes = Date.new(data.year, data.month, -1).to_s
        
        resultado = client.exec_params(
          "SELECT COUNT(*) as total FROM presencas p
           JOIN aulas a ON p.aula_id = a.id
           WHERE a.data_aula BETWEEN $1 AND $2 AND p.presente = TRUE",
          [inicio_mes, fim_mes]
        ).first['total'].to_i
        
        meses.push("#{data.strftime('%b/%Y')}")
        dados.push(resultado)
      end
      
      {labels: meses, data: dados}
    end
  end
end