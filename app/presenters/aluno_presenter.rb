require_relative 'base_presenter'

class AlunoPresenter < BasePresenter
  def status
    @model['bolsista'] == 't' || @model['bolsista'] == true ? 'Bolsista' : 'Pagante'
  end
  
  def data_nascimento_formatada
    format_date(@model['data_nascimento'])
  end
  
  def data_hoje_para_input
    Date.today.strftime('%Y-%m-%d')
  end
  
  def idade
    return 'N/A' if @model['data_nascimento'].nil? || @model['data_nascimento'].to_s.empty?
    
    begin
      data_nasc = Date.parse(@model['data_nascimento'].to_s)
      hoje = Date.today
      idade = hoje.year - data_nasc.year
      idade -= 1 if hoje < Date.new(hoje.year, data_nasc.month, data_nasc.day)
      idade.to_s
    rescue
      'N/A'
    end
  end
  
  def problema_saude
    (@model['saude_problema'] && !@model['saude_problema'].empty?) ? @model['saude_problema'] : 'Não informado'
  end
  
  def uso_medicacao
    (@model['saude_medicacao'] && !@model['saude_medicacao'].empty?) ? @model['saude_medicacao'] : 'Não informado'
  end
  
  def historico_lesoes
    (@model['saude_lesao'] && !@model['saude_lesao'].empty?) ? @model['saude_lesao'] : 'Não informado'
  end
  
  def uso_substancias
    (@model['saude_substancia'] && !@model['saude_substancia'].empty?) ? @model['saude_substancia'] : 'Não informado'
  end
  
  def possui_graduacoes?(graduacoes)
    graduacoes && graduacoes.any?
  end
  
  def formatar_graduacao(graduacao)
    data = format_date(graduacao['data_graduacao'])
    "#{graduacao['faixa']} em #{data}"
  end
end