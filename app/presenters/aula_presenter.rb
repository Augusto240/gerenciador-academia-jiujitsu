require_relative 'base_presenter'

class AulaPresenter < BasePresenter
  def data_formatada
    format_date(@model['data_aula'])
  end
  
  def descricao
    @model['descricao'].to_s.empty? ? '—' : @model['descricao']
  end
  
  def turma_formatada
    @model['turma'].to_s.empty? ? '—' : @model['turma']
  end
  
  def aluno_presente?(aluno)
    aluno['presente'] == 't' || aluno['presente'] == true
  end
end