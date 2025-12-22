require_relative 'test_helper'

class PresenterTest < Minitest::Test
  def test_aluno_presenter_status_pagante
    aluno = { 'nome' => 'João', 'bolsista' => 'f' }
    presenter = AlunoPresenter.new(aluno)
    assert_equal 'Pagante', presenter.status
  end

  def test_aluno_presenter_status_bolsista
    aluno = { 'nome' => 'Maria', 'bolsista' => 't' }
    presenter = AlunoPresenter.new(aluno)
    assert_equal 'Bolsista', presenter.status
  end

  def test_aluno_presenter_idade_calculo
    data_nascimento = (Date.today - (20 * 365)).to_s  # Aproximadamente 20 anos
    aluno = { 'nome' => 'Pedro', 'data_nascimento' => data_nascimento }
    presenter = AlunoPresenter.new(aluno)
    # A idade deve ser aproximadamente 20 (pode variar por dias)
    idade = presenter.idade.to_i
    assert idade >= 19 && idade <= 21
  end

  def test_aluno_presenter_idade_sem_data
    aluno = { 'nome' => 'Ana', 'data_nascimento' => nil }
    presenter = AlunoPresenter.new(aluno)
    assert_equal 'N/A', presenter.idade
  end

  def test_aluno_presenter_data_formatada
    aluno = { 'nome' => 'Carlos', 'data_nascimento' => '2000-05-15' }
    presenter = AlunoPresenter.new(aluno)
    assert_equal '15/05/2000', presenter.data_nascimento_formatada
  end

  def test_base_presenter_format_currency
    model = {}
    presenter = BasePresenter.new(model)
    assert_equal 'R$ 70.00', presenter.format_currency(70)
    assert_equal 'R$ 150.50', presenter.format_currency(150.5)
  end

  def test_base_presenter_format_date
    model = {}
    presenter = BasePresenter.new(model)
    assert_equal '15/05/2000', presenter.format_date('2000-05-15')
    assert_equal 'N/A', presenter.format_date(nil)
    assert_equal 'N/A', presenter.format_date('')
  end

  def test_aula_presenter_descricao_vazia
    aula = { 'descricao' => '' }
    presenter = AulaPresenter.new(aula)
    assert_equal '—', presenter.descricao
  end

  def test_aula_presenter_descricao_com_valor
    aula = { 'descricao' => 'Treino de guarda' }
    presenter = AulaPresenter.new(aula)
    assert_equal 'Treino de guarda', presenter.descricao
  end

  def test_aula_presenter_aluno_presente
    aula = {}
    presenter = AulaPresenter.new(aula)
    assert presenter.aluno_presente?({ 'presente' => 't' })
    assert presenter.aluno_presente?({ 'presente' => true })
    refute presenter.aluno_presente?({ 'presente' => 'f' })
    refute presenter.aluno_presente?({ 'presente' => false })
  end
end
