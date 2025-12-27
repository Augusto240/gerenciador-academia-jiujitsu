require_relative 'test_helper'

class PagamentoServiceTest < Minitest::Test
  def test_registrar_pagamento_rejeita_valor_zero_ou_negativo
    result = PagamentoService.registrar_pagamento(1, 1, 0, Date.today.to_s)
    refute result[:success]
    assert_includes result[:message], "positivo"
    
    result = PagamentoService.registrar_pagamento(1, 1, -50, Date.today.to_s)
    refute result[:success]
    assert_includes result[:message], "positivo"
  end
  
  def test_registrar_pagamento_retorna_hash_com_success
    result = PagamentoService.registrar_pagamento(999999, 999999, 100, Date.today.to_s)
    assert_kind_of Hash, result
    assert result.key?(:success)
    assert result.key?(:message)
  end
end

class AulaServiceTest < Minitest::Test
  def test_criar_e_inicializar_retorna_hash_com_success
    # Com parâmetros inválidos deve retornar erro, mas formato correto
    result = AulaService.criar_e_inicializar({})
    assert_kind_of Hash, result
    assert result.key?(:success)
    assert result.key?(:message)
  end
  
  def test_atualizar_presencas_retorna_hash
    result = AulaService.atualizar_presencas(-1, [])
    assert_kind_of Hash, result
    assert result.key?(:success)
    assert result.key?(:message)
  end
end
