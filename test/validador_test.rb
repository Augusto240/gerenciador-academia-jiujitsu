require_relative 'test_helper'

class ValidadorTest < Minitest::Test
  include Validador

  def test_valida_nome_vazio
    params = { 'nome' => '', 'cor_faixa' => 'Branca', 'turma' => 'Adultos', 'modalidade' => 'Jiu Jitsu' }
    erros = validar_aluno(params)
    assert_includes erros, "Nome é obrigatório"
  end

  def test_valida_nome_curto
    params = { 'nome' => 'A', 'cor_faixa' => 'Branca', 'turma' => 'Adultos', 'modalidade' => 'Jiu Jitsu' }
    erros = validar_aluno(params)
    assert_includes erros, "Nome deve ter entre 2 e 100 caracteres"
  end

  def test_valida_faixa_invalida
    params = { 'nome' => 'João Silva', 'cor_faixa' => 'Rosa', 'turma' => 'Adultos', 'modalidade' => 'Jiu Jitsu' }
    erros = validar_aluno(params)
    assert_includes erros, "Faixa inválida"
  end

  def test_valida_turma_invalida
    params = { 'nome' => 'João Silva', 'cor_faixa' => 'Branca', 'turma' => 'Inexistente', 'modalidade' => 'Jiu Jitsu' }
    erros = validar_aluno(params)
    assert_includes erros, "Turma inválida"
  end

  def test_valida_modalidade_invalida
    params = { 'nome' => 'João Silva', 'cor_faixa' => 'Branca', 'turma' => 'Adultos', 'modalidade' => 'Karate' }
    erros = validar_aluno(params)
    assert_includes erros, "Modalidade inválida"
  end

  def test_valida_faixa_muay_thai_correta
    params = { 'nome' => 'Maria Silva', 'cor_faixa' => 'Sem graduação', 'turma' => 'Adultos', 'modalidade' => 'Muay Thai' }
    erros = validar_aluno(params)
    refute_includes erros, "Faixa inválida para Muay Thai"
  end

  def test_valida_faixa_muay_thai_incorreta
    params = { 'nome' => 'Maria Silva', 'cor_faixa' => 'Cinza/Branca', 'turma' => 'Adultos', 'modalidade' => 'Muay Thai' }
    erros = validar_aluno(params)
    assert_includes erros, "Faixa inválida para Muay Thai"
  end

  def test_valida_aluno_correto_jiu_jitsu
    params = { 
      'nome' => 'João da Silva', 
      'cor_faixa' => 'Branca', 
      'turma' => 'Adultos', 
      'modalidade' => 'Jiu Jitsu',
      'data_nascimento' => '2000-01-01'
    }
    erros = validar_aluno(params)
    assert_empty erros
  end

  def test_valida_data_nascimento_futura
    params = { 
      'nome' => 'João da Silva', 
      'cor_faixa' => 'Branca', 
      'turma' => 'Adultos', 
      'modalidade' => 'Jiu Jitsu',
      'data_nascimento' => (Date.today + 1).to_s
    }
    erros = validar_aluno(params)
    assert_includes erros, "Data de nascimento não pode ser futura"
  end

  def test_valida_idade_minima
    params = { 
      'nome' => 'Bebê', 
      'cor_faixa' => 'Branca', 
      'turma' => 'Kids 2 a 3 anos', 
      'modalidade' => 'Jiu Jitsu',
      'data_nascimento' => (Date.today - 365).to_s  # 1 ano de idade
    }
    erros = validar_aluno(params)
    assert_includes erros, "Idade mínima para cadastro é 2 anos"
  end

  def test_valida_aula_data_obrigatoria
    params = { 'data_aula' => '', 'turma' => 'Adultos' }
    erros = validar_aula(params)
    assert_includes erros, "Data da aula é obrigatória"
  end

  def test_valida_aula_data_futura
    params = { 'data_aula' => (Date.today + 1).to_s, 'turma' => 'Adultos' }
    erros = validar_aula(params)
    assert_includes erros, "Data da aula não pode ser futura"
  end

  def test_valida_pagamento_valor_obrigatorio
    params = { 'valor_pago' => '', 'data_pagamento' => Date.today.to_s }
    erros = validar_pagamento(params)
    assert_includes erros, "Valor do pagamento é obrigatório"
  end

  def test_valida_pagamento_valor_positivo
    params = { 'valor_pago' => '-50', 'data_pagamento' => Date.today.to_s }
    erros = validar_pagamento(params)
    assert_includes erros, "Valor do pagamento deve ser positivo"
  end

  def test_valida_graduacao_faixa_obrigatoria
    params = { 'faixa' => '', 'data_graduacao' => Date.today.to_s }
    erros = validar_graduacao(params)
    assert_includes erros, "Faixa é obrigatória"
  end
end
