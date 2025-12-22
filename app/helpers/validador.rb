module Validador
  def validar_aluno(params)
    erros = []
    
    # Validações básicas
    erros << "Nome é obrigatório" if params['nome'].to_s.strip.empty?
    erros << "Nome deve ter entre 2 e 100 caracteres" if params['nome'].to_s.length < 2 || params['nome'].to_s.length > 100
    erros << "Faixa inválida" unless FAIXAS.include?(params['cor_faixa'])
    erros << "Turma inválida" unless TURMAS.include?(params['turma'])
    
    # Validação de data de nascimento
    if params['data_nascimento'] && !params['data_nascimento'].empty?
      begin
        data_nasc = Date.parse(params['data_nascimento'])
        idade = calcular_idade(data_nasc)
        
        erros << "Data de nascimento não pode ser futura" if data_nasc > Date.today
        erros << "Data de nascimento inválida (muito antiga)" if data_nasc < Date.new(1900, 1, 1)
        erros << "Idade mínima para cadastro é 2 anos" if idade < 2
        erros << "Idade máxima para cadastro é 100 anos" if idade > 100
      rescue Date::Error
        erros << "Data de nascimento em formato inválido"
      end
    end
    
    # Validação de campos de saúde (opcional)
    ['saude_problema', 'saude_medicacao', 'saude_lesao', 'saude_substancia'].each do |campo|
      if params[campo] && params[campo].length > 500
        erros << "Campo '#{campo.gsub('saude_', '')}' não deve exceder 500 caracteres"
      end
    end
    
    erros
  end

  def validar_aula(params)
    erros = []
    
    erros << "Data da aula é obrigatória" if params['data_aula'].to_s.strip.empty?
    
    if params['data_aula'] && !params['data_aula'].empty?
      begin
        data_aula = Date.parse(params['data_aula'])
        erros << "Data da aula não pode ser futura" if data_aula > Date.today
        erros << "Data da aula muito antiga" if data_aula < Date.today - 365  # Não permitir datas de mais de 1 ano atrás
      rescue Date::Error
        erros << "Data da aula em formato inválido"
      end
    end
    
    erros << "Turma inválida" if !params['turma'].empty? && !TURMAS.include?(params['turma'])
    
    if params['descricao'] && params['descricao'].length > 255
      erros << "Descrição não deve exceder 255 caracteres"
    end
    
    erros
  end

  def validar_pagamento(params)
    erros = []
    
    erros << "Valor do pagamento é obrigatório" if params['valor_pago'].to_s.strip.empty?
    erros << "Data do pagamento é obrigatória" if params['data_pagamento'].to_s.strip.empty?
    
    if params['valor_pago']
      begin
        valor = Float(params['valor_pago'])
        erros << "Valor do pagamento deve ser positivo" if valor <= 0
      rescue ArgumentError
        erros << "Valor do pagamento inválido"
      end
    end
    
    if params['data_pagamento'] && !params['data_pagamento'].empty?
      begin
        data_pag = Date.parse(params['data_pagamento'])
        erros << "Data do pagamento não pode ser futura" if data_pag > Date.today
        erros << "Data do pagamento muito antiga" if data_pag < Date.today - 365*2  # Limitar a 2 anos atrás
      rescue Date::Error
        erros << "Data do pagamento em formato inválido"
      end
    end
    
    erros
  end
  
  def validar_graduacao(params)
    erros = []
    
    erros << "Faixa é obrigatória" if params['faixa'].to_s.strip.empty?
    erros << "Data da graduação é obrigatória" if params['data_graduacao'].to_s.strip.empty?
    
    if params['faixa'] && !FAIXAS.include?(params['faixa'])
      erros << "Faixa inválida"
    end
    
    if params['data_graduacao'] && !params['data_graduacao'].empty?
      begin
        data_grad = Date.parse(params['data_graduacao'])
        erros << "Data da graduação não pode ser futura" if data_grad > Date.today
        erros << "Data da graduação muito antiga" if data_grad < Date.today - 365*10  # Limitar a 10 anos atrás
      rescue Date::Error
        erros << "Data da graduação em formato inválido"
      end
    end
    
    erros
  end
  
  def calcular_idade(data_nasc)
    hoje = Date.today
    idade = hoje.year - data_nasc.year
    idade -= 1 if hoje < Date.new(hoje.year, data_nasc.month, data_nasc.day)
    idade
  end
end