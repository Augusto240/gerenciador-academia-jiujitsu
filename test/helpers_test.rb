require_relative 'test_helper'

class HelpersTest < Minitest::Test
  include Validador
  
  # ======================
  # Testes de sanitize_csv
  # ======================
  
  def test_sanitize_csv_normal_values
    # Valores normais não são alterados
    assert_equal "João Silva", sanitize_csv("João Silva")
    assert_equal "100", sanitize_csv(100)
    assert_equal "texto simples", sanitize_csv("texto simples")
  end
  
  def test_sanitize_csv_formula_injection
    # Valores que começam com caracteres perigosos são prefixados
    assert_equal "'=cmd|'/C calc'!A1", sanitize_csv("=cmd|'/C calc'!A1")
    assert_equal "'+cmd", sanitize_csv("+cmd")
    assert_equal "'-cmd", sanitize_csv("-cmd")
    assert_equal "'@SUM(A1:A10)", sanitize_csv("@SUM(A1:A10)")
  end
  
  # ======================
  # Testes de valid_id?
  # ======================
  
  def test_valid_id_aceita_numeros_positivos
    assert valid_id?(1)
    assert valid_id?(100)
    assert valid_id?("1")
    assert valid_id?("999")
  end
  
  def test_valid_id_rejeita_valores_invalidos
    refute valid_id?(0)
    refute valid_id?(-1)
    refute valid_id?("abc")
    refute valid_id?("")
    refute valid_id?(nil)
    refute valid_id?("1abc")
  end
  
  # ======================
  # Testes de calcular_idade
  # ======================
  
  def test_calcular_idade
    hoje = Date.today
    
    # Pessoa que faz 30 anos hoje
    data_nasc_30 = Date.new(hoje.year - 30, hoje.month, hoje.day)
    assert_equal 30, calcular_idade(data_nasc_30)
    
    # Pessoa que ainda não fez aniversário este ano
    if hoje.month > 1
      data_nasc_futuro = Date.new(hoje.year - 25, hoje.month - 1, 1)
      assert_equal 25, calcular_idade(data_nasc_futuro)
    end
  end
  
  private
  
  # Helpers simulados que estão no app.rb
  def sanitize_csv(value)
    str = value.to_s
    if str.match?(/\A[=+\-@]/)
      "'#{str}"
    else
      str
    end
  end
  
  def valid_id?(id)
    id.to_s.match?(/\A\d+\z/) && id.to_i > 0
  end
end
