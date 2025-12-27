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
      # Query única com GROUP BY para evitar N+1 (otimizado)
      data_inicio = (Date.today << quantidade).strftime('%Y-%m-01')
      data_fim = Date.today.strftime('%Y-%m-%d')
      
      resultado = client.exec_params(
        "SELECT 
           DATE_TRUNC('month', a.data_aula) as mes,
           COUNT(*) as total
         FROM presencas p
         JOIN aulas a ON p.aula_id = a.id
         WHERE p.presente = TRUE 
           AND a.data_aula >= $1
           AND a.data_aula <= $2
         GROUP BY DATE_TRUNC('month', a.data_aula)
         ORDER BY mes",
        [data_inicio, data_fim]
      )
      
      # Criar hash para busca rápida dos resultados
      dados_por_mes = {}
      resultado.each do |row|
        mes_key = Date.parse(row['mes']).strftime('%Y-%m')
        dados_por_mes[mes_key] = row['total'].to_i
      end
      
      # Construir arrays de labels e dados para os últimos N meses
      meses = []
      dados = []
      
      quantidade.downto(1) do |i|
        data = Date.today << i
        mes_key = data.strftime('%Y-%m')
        
        meses.push(data.strftime('%b/%Y'))
        dados.push(dados_por_mes[mes_key] || 0)
      end
      
      {labels: meses, data: dados}
    end
  end
end