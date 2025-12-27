require_relative 'test_helper'

class NotificacaoModelTest < Minitest::Test
  def setup
    # Limpar notificações de teste
    with_db do |client|
      client.exec("DELETE FROM notificacoes WHERE titulo LIKE 'Teste%'")
    end
  end
  
  def teardown
    # Limpar notificações de teste após cada teste
    with_db do |client|
      client.exec("DELETE FROM notificacoes WHERE titulo LIKE 'Teste%'")
    end
  end
  
  def test_criar_notificacao
    result = Notificacao.criar("Teste - Notificação", "Mensagem de teste", "info")
    
    assert result
    assert result['id']
  end
  
  def test_pendentes_retorna_apenas_nao_lidas
    # Criar uma notificação
    Notificacao.criar("Teste - Pendente", "Esta não foi lida", "info")
    
    pendentes = Notificacao.pendentes
    
    assert pendentes.is_a?(Array)
    # Verificar que pelo menos a notificação criada está na lista
    mensagens = pendentes.map { |n| n['mensagem'] }
    assert_includes mensagens, "Esta não foi lida"
  end
  
  def test_marcar_como_lida
    # Criar notificação
    notif = Notificacao.criar("Teste - Lida", "Será marcada como lida", "info")
    
    # Marcar como lida
    Notificacao.marcar_como_lida(notif['id'])
    
    # Verificar que não aparece mais nas pendentes
    pendentes = Notificacao.pendentes
    ids = pendentes.map { |n| n['id'] }
    refute_includes ids, notif['id']
  end
  
  def test_todas_retorna_array
    result = Notificacao.todas
    
    assert result.is_a?(Array)
  end
  
  def test_criar_com_tipo_warning
    # Usar timestamp para garantir mensagem única
    mensagem_unica = "Aviso de teste #{Time.now.to_i}"
    result = Notificacao.criar("Teste - Warning", mensagem_unica, "warning")
    
    # Verificar se a notificação foi criada (pode retornar nil se usar ON CONFLICT)
    pendentes = Notificacao.pendentes
    mensagens = pendentes.map { |n| n['mensagem'] }
    assert_includes mensagens, mensagem_unica
  end
end
