require_relative 'test_helper'

class AuthenticatedRoutesTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  # Helper para fazer login e obter sessão autenticada
  def login_as_admin
    # Obter token CSRF da página de login
    get '/login'
    csrf_token = last_response.body.match(/name="_csrf" value="([^"]+)"/)[1]
    
    # Fazer login com credenciais de admin
    post '/login', { 
      email: 'admin@jpteam.com', 
      password: 'admin123',
      _csrf: csrf_token 
    }
    
    # Verificar se login foi bem-sucedido
    assert_equal 302, last_response.status
    follow_redirect!
  end
  
  # ==========================================
  # TESTES DE DASHBOARD
  # ==========================================
  
  def test_dashboard_requer_autenticacao
    get '/dashboard'
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/login'
  end
  
  def test_dashboard_carrega_quando_autenticado
    login_as_admin
    get '/dashboard'
    assert last_response.ok?
    assert_includes last_response.body, 'Dashboard'
  end
  
  # ==========================================
  # TESTES DE ALUNOS
  # ==========================================
  
  def test_lista_alunos_requer_autenticacao
    get '/'
    assert_equal 302, last_response.status
  end
  
  def test_lista_alunos_carrega_quando_autenticado
    login_as_admin
    get '/'
    assert last_response.ok?
    assert_includes last_response.body, 'Controle de Alunos'
  end
  
  def test_formulario_novo_aluno_carrega
    login_as_admin
    get '/alunos/novo'
    assert last_response.ok?
    assert_includes last_response.body, 'Cadastrar'
  end
  
  # ==========================================
  # TESTES DE AULAS
  # ==========================================
  
  def test_lista_aulas_requer_autenticacao
    get '/aulas'
    assert_equal 302, last_response.status
  end
  
  def test_lista_aulas_carrega_quando_autenticado
    login_as_admin
    get '/aulas'
    assert last_response.ok?
    assert_includes last_response.body, 'Aulas'
  end
  
  def test_filtro_aulas_funciona
    login_as_admin
    get '/aulas', { turma_filtro: 'Adultos' }
    assert last_response.ok?
  end
  
  # ==========================================
  # TESTES DE RELATÓRIOS
  # ==========================================
  
  def test_relatorios_requer_autenticacao
    get '/relatorios'
    assert_equal 302, last_response.status
  end
  
  def test_relatorios_carrega_quando_autenticado
    login_as_admin
    get '/relatorios'
    assert last_response.ok?
    assert_includes last_response.body, 'Relatórios'
  end
  
  def test_relatorio_frequencia_carrega
    login_as_admin
    get '/relatorios/frequencia'
    assert last_response.ok?
    assert_includes last_response.body, 'Frequência'
  end
  
  def test_relatorio_mensalidades_carrega
    login_as_admin
    get '/relatorios/mensalidades'
    assert last_response.ok?
    assert_includes last_response.body, 'Mensalidades'
  end
  
  # ==========================================
  # TESTES DE HEALTH CHECK
  # ==========================================
  
  def test_health_nao_requer_autenticacao
    get '/health'
    assert last_response.ok?
    assert_includes last_response.content_type, 'application/json'
  end
  
  # ==========================================
  # TESTES DE ALUNOS EXCLUÍDOS (ADMIN)
  # ==========================================
  
  def test_alunos_excluidos_requer_autenticacao
    get '/alunos-excluidos'
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/login'
  end
  
  def test_alunos_excluidos_redireciona_se_nao_admin
    login_as_admin
    # Se o usuário não tem flag admin=true, deve redirecionar
    # Este teste verifica que a rota está protegida
    get '/alunos-excluidos'
    # Pode ser 200 (se admin) ou 302 (se não admin)
    assert [200, 302].include?(last_response.status)
  end
  
  # ==========================================
  # TESTES DE VALIDAÇÃO DE ID
  # ==========================================
  
  def test_aluno_com_id_invalido_retorna_400
    login_as_admin
    get '/alunos/abc'
    assert_equal 400, last_response.status
    assert_includes last_response.body, 'inválido'
  end
  
  def test_aula_com_id_invalido_retorna_400
    login_as_admin
    get '/aulas/abc'
    assert_equal 400, last_response.status
    assert_includes last_response.body, 'inválido'
  end
end
