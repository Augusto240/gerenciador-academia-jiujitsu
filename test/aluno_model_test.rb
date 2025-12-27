require_relative 'test_helper'

class AlunoModelTest < Minitest::Test
  
  # ==========================================
  # TESTES DE CRIAÇÃO
  # ==========================================
  
  def test_criar_aluno_com_dados_validos
    aluno_params = {
      'nome' => 'Aluno Teste CI',
      'modalidade' => 'Jiu Jitsu',
      'cor_faixa' => 'Branca',
      'turma' => 'Adultos',
      'data_nascimento' => '2000-01-01'
    }
    
    result = Aluno.criar(aluno_params)
    
    assert result, "Deveria retornar o aluno criado"
    assert result['id'], "Deveria ter um ID"
    
    # Buscar o aluno para verificar se foi salvo
    aluno = Aluno.buscar_por_id(result['id'])
    assert_equal 'Aluno Teste CI', aluno['nome']
    
    # Limpar: excluir permanentemente o aluno criado
    Aluno.excluir_permanente(result['id']) if result && result['id']
  end
  
  def test_criar_aluno_sem_data_nascimento
    aluno_params = {
      'nome' => 'Aluno Sem Data',
      'modalidade' => 'Jiu Jitsu',
      'cor_faixa' => 'Branca',
      'turma' => 'Adultos',
      'data_nascimento' => nil
    }
    
    result = Aluno.criar(aluno_params)
    
    assert result, "Deveria criar mesmo sem data de nascimento"
    assert result['id'], "Deveria ter um ID"
    
    # Limpar
    Aluno.excluir_permanente(result['id']) if result && result['id']
  end
  
  def test_criar_aluno_com_data_nascimento_vazia
    aluno_params = {
      'nome' => 'Aluno Data Vazia',
      'modalidade' => 'Jiu Jitsu',
      'cor_faixa' => 'Branca',
      'turma' => 'Adultos',
      'data_nascimento' => ''
    }
    
    result = Aluno.criar(aluno_params)
    
    assert result, "Deveria criar mesmo com data vazia"
    
    # Limpar
    Aluno.excluir_permanente(result['id']) if result && result['id']
  end
  
  # ==========================================
  # TESTES DE BUSCA
  # ==========================================
  
  def test_todos_retorna_array
    result = Aluno.todos
    assert_instance_of Array, result
  end
  
  def test_buscar_por_id_retorna_aluno
    # Buscar primeiro aluno existente
    alunos = Aluno.todos
    
    if alunos.any?
      primeiro = alunos.first
      result = Aluno.buscar_por_id(primeiro['id'])
      assert result
      assert_equal primeiro['id'], result['id']
    end
  end
  
  def test_buscar_por_id_inexistente_retorna_nil
    result = Aluno.buscar_por_id(999999)
    assert_nil result
  end
  
  def test_total_retorna_inteiro
    result = Aluno.total
    assert_kind_of Integer, result
    assert result >= 0
  end
  
  # ==========================================
  # TESTES DE FILTROS
  # ==========================================
  
  def test_buscar_com_filtros_retorna_hash
    result = Aluno.buscar_com_filtros({}, 1, 10)
    assert_instance_of Hash, result
    assert result[:alunos]
    assert result[:total]
    assert result[:pagina_atual]
  end
  
  def test_buscar_com_filtro_modalidade
    result = Aluno.buscar_com_filtros({ modalidade: 'Jiu Jitsu' }, 1, 10)
    assert_instance_of Hash, result
    
    # Todos os resultados devem ser da modalidade filtrada
    result[:alunos].each do |aluno|
      assert_equal 'Jiu Jitsu', aluno['modalidade']
    end
  end
  
  def test_buscar_com_filtro_turma
    result = Aluno.buscar_com_filtros({ turma: 'Adultos' }, 1, 10)
    assert_instance_of Hash, result
    
    result[:alunos].each do |aluno|
      assert_equal 'Adultos', aluno['turma']
    end
  end
  
  # ==========================================
  # TESTES DE EXCLUSÃO (SOFT DELETE)
  # ==========================================
  
  def test_excluir_marca_deleted_at
    # Criar aluno de teste
    aluno = Aluno.criar({
      'nome' => 'Aluno Para Excluir',
      'modalidade' => 'Jiu Jitsu',
      'cor_faixa' => 'Branca',
      'turma' => 'Adultos',
      'data_nascimento' => '1990-05-15'
    })
    
    assert aluno, "Deveria criar o aluno"
    assert aluno['id'], "Deveria ter um ID"
    
    # Excluir (soft delete)
    Aluno.excluir(aluno['id'])
    
    # Buscar não deve encontrar (soft delete)
    result = Aluno.buscar_por_id(aluno['id'])
    assert_nil result, "Aluno excluído não deveria ser encontrado"
    
    # Limpar permanentemente
    Aluno.excluir_permanente(aluno['id'])
  end
  
  def test_buscar_excluidos_retorna_array
    result = Aluno.buscar_excluidos
    assert_instance_of Array, result
  end
  
  # ==========================================
  # TESTES DE RESTAURAR ALUNO
  # ==========================================
  
  def test_restaurar_aluno_excluido
    # Criar aluno de teste
    aluno = Aluno.criar({
      'nome' => 'Aluno Para Restaurar',
      'modalidade' => 'Muay Thai',
      'cor_faixa' => 'Branca',
      'turma' => 'Adultos',
      'data_nascimento' => '1995-03-20'
    })
    
    id = aluno['id']
    
    # Excluir
    Aluno.excluir(id)
    
    # Verificar que está excluído
    assert_nil Aluno.buscar_por_id(id)
    
    # Restaurar
    Aluno.restaurar(id)
    
    # Deve estar visível novamente
    restaurado = Aluno.buscar_por_id(id)
    assert restaurado, "Aluno deveria estar restaurado"
    assert_equal 'Aluno Para Restaurar', restaurado['nome']
    
    # Limpar
    Aluno.excluir_permanente(id)
  end
  
  # ==========================================
  # TESTES DE ANIVERSARIANTES
  # ==========================================
  
  def test_aniversariantes_do_mes_retorna_array
    result = Aluno.aniversariantes_do_mes
    assert_instance_of Array, result
  end
end
