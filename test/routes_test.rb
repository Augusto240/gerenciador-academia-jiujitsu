require_relative 'test_helper'

class AppRoutesTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    # Simular sessão de usuário logado
    @session = { 'rack.session' => { user_id: 1 } }
  end

  def test_redireciona_para_login_sem_sessao
    get '/'
    assert_equal 302, last_response.status
    assert_includes last_response.headers['Location'], '/login'
  end

  def test_pagina_login_carrega
    get '/login'
    assert last_response.ok?
    # Verificar elementos do novo design
    assert_includes last_response.body, 'JPM Team'
  end

  def test_pagina_login_tem_formulario
    get '/login'
    assert_includes last_response.body, '<form action="/login"'
    assert_includes last_response.body, 'email'
    assert_includes last_response.body, 'password'
  end

  def test_login_com_credenciais_invalidas
    # Primeiro, obter o token CSRF da página de login
    get '/login'
    csrf_token = last_response.body.match(/name="_csrf" value="([^"]+)"/)[1]
    
    post '/login', { email: 'invalido@email.com', password: 'senhaerrada', _csrf: csrf_token }
    assert_equal 302, last_response.status
    follow_redirect!
    assert_includes last_response.body, 'login' # Redireciona para login
  end
  
  def test_health_endpoint
    get '/health'
    assert last_response.ok?
    assert_includes last_response.content_type, 'application/json'
    
    body = JSON.parse(last_response.body)
    assert_includes ['healthy', 'unhealthy'], body['status']
    assert body['timestamp']
    assert body['database']
  end
end
