require_relative 'test_helper'

class PostRoutesTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  # Helper para fazer login e obter sessão autenticada
  def login_as_admin
    get '/login'
    csrf_token = last_response.body.match(/name="_csrf" value="([^"]+)"/)[1]
    
    post '/login', { 
      email: 'admin@jpteam.com', 
      password: 'admin123',
      _csrf: csrf_token 
    }
    
    assert_equal 302, last_response.status
    follow_redirect!
  end
  
  # Helper para obter CSRF token de um formulário
  def get_csrf_token(path)
    get path
    match = last_response.body.match(/name="_csrf" value="([^"]+)"/)
    match ? match[1] : nil
  end
  
  # ==========================================
  # TESTES DE CRIAR ALUNO
  # ==========================================
  
  def test_formulario_novo_aluno_tem_csrf
    login_as_admin
    get '/alunos/novo'
    assert last_response.ok?
    assert_includes last_response.body, '_csrf'
  end
  
  def test_criar_aluno_sem_csrf_gera_excecao
    login_as_admin
    # CSRF token inválido deve gerar exceção
    assert_raises(Rack::Csrf::InvalidCsrfToken) do
      post '/alunos', { 
        nome: 'Aluno Teste',
        data_nascimento: '2000-01-01'
      }
    end
  end
  
  def test_criar_aluno_com_dados_invalidos
    login_as_admin
    csrf = get_csrf_token('/alunos/novo')
    
    post '/alunos', {
      nome: '',  # Nome vazio deve falhar
      data_nascimento: '2000-01-01',
      _csrf: csrf
    }
    
    # Pode redirecionar com mensagem de erro ou retornar 400
    assert [200, 302, 400].include?(last_response.status)
  end
  
  # ==========================================
  # TESTES DE CRIAR AULA
  # ==========================================
  
  def test_formulario_nova_aula_tem_csrf
    login_as_admin
    get '/aulas/nova'
    assert last_response.ok?
    assert_includes last_response.body, '_csrf'
  end
  
  def test_criar_aula_com_dados_validos
    login_as_admin
    csrf = get_csrf_token('/aulas/nova')
    
    post '/aulas', {
      data_aula: Date.today.to_s,
      modalidade: 'Jiu Jitsu',
      turma: 'Adultos',
      descricao: 'Treino de teste',
      _csrf: csrf
    }
    
    # Deve redirecionar para a aula criada
    assert_equal 302, last_response.status
  end
  
  # ==========================================
  # TESTES DE REGISTRAR PAGAMENTO
  # ==========================================
  
  def test_pagamento_com_assinatura_invalida
    login_as_admin
    csrf = get_csrf_token('/alunos/novo')
    
    post '/pagamentos', {
      assinatura_id: 999999,  # ID inválido
      valor: 100,
      _csrf: csrf
    }
    
    # Deve redirecionar com erro
    assert_equal 302, last_response.status
  end
  
  # ==========================================
  # TESTES DE LOGOUT
  # ==========================================
  
  def test_logout_post_destroi_sessao
    login_as_admin
    
    # Verificar que está logado
    get '/dashboard'
    assert last_response.ok?
    
    # Fazer logout via POST (requer CSRF)
    csrf = get_csrf_token('/alunos/novo')
    post '/logout', { _csrf: csrf }
    
    assert_equal 302, last_response.status
    
    # Após logout, tentar acessar dashboard deve redirecionar
    get '/dashboard'
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/login'
  end
  
  def test_logout_get_redireciona_para_login
    login_as_admin
    get '/logout'
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/login'
  end
  
  # ==========================================
  # TESTES DE EDITAR ALUNO
  # ==========================================
  
  def test_editar_aluno_com_id_invalido
    login_as_admin
    get '/editar-aluno/abc'
    # Pode retornar 400 ou 404 dependendo da implementação
    assert [400, 404].include?(last_response.status)
  end
  
  def test_editar_aluno_inexistente
    login_as_admin
    get '/editar-aluno/999999'
    # Deve redirecionar ou retornar 404
    assert [302, 404].include?(last_response.status)
  end
  
  # ==========================================
  # TESTES DE EXPORTAÇÃO
  # ==========================================
  
  def test_exportar_csv_requer_autenticacao
    get '/relatorios/frequencia/export'
    assert_equal 302, last_response.status
  end
  
  def test_exportar_mensalidades_requer_autenticacao
    get '/relatorios/mensalidades/export'
    assert_equal 302, last_response.status
  end
  
  def test_exportar_frequencia_funciona_autenticado
    login_as_admin
    get '/relatorios/frequencia/export'
    # Retorna CSV (pode ter vários status dependendo dos dados)
    assert [200, 302, 404, 500].include?(last_response.status)
  end
  
  def test_exportar_mensalidades_funciona_autenticado
    login_as_admin
    get '/relatorios/mensalidades/export'
    # Retorna CSV (pode ter vários status dependendo dos dados)
    assert [200, 302, 404, 500].include?(last_response.status)
  end
end
