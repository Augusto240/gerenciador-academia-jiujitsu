require_relative 'test_helper'

class AlunoModelTest < Minitest::Test
  def test_sanitize_like_escapa_caracteres_especiais
    assert_equal "teste\\%", Aluno.sanitize_like("teste%")
    assert_equal "teste\\_", Aluno.sanitize_like("teste_")
    assert_equal "teste\\\\", Aluno.sanitize_like("teste\\")
    assert_equal "nome normal", Aluno.sanitize_like("nome normal")
  end
  
  def test_total_retorna_numero
    total = Aluno.total
    assert_kind_of Integer, total
    assert total >= 0
  end
end

class AssinaturaModelTest < Minitest::Test
  def test_verificar_status_retorna_hash_com_status_e_cor
    # Quando assinatura não existe
    result = Assinatura.verificar_status(-1)
    assert_kind_of Hash, result
    assert result.key?(:status)
    assert result.key?(:cor)
  end
end

class AulaModelTest < Minitest::Test
  def test_total_no_mes_atual_retorna_numero
    total = Aula.total_no_mes_atual
    assert_kind_of Integer, total
    assert total >= 0
  end
end

class PresencaModelTest < Minitest::Test
  def test_total_no_mes_atual_retorna_numero
    total = Presenca.total_no_mes_atual
    assert_kind_of Integer, total
    assert total >= 0
  end
  
  def test_historico_ultimos_meses_retorna_hash_com_labels_e_data
    result = Presenca.historico_ultimos_meses
    assert_kind_of Hash, result
    assert result.key?(:labels)
    assert result.key?(:data)
    assert_kind_of Array, result[:labels]
    assert_kind_of Array, result[:data]
  end
end
