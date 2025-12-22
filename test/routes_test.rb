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
    assert_includes last_response.body, 'Acesso ao Sistema'
  end

  def test_pagina_login_tem_formulario
    get '/login'
    assert_includes last_response.body, '<form action="/login"'
    assert_includes last_response.body, 'email'
    assert_includes last_response.body, 'password'
  end

  def test_login_com_credenciais_invalidas
    post '/login', { email: 'invalido@email.com', password: 'senhaerrada' }
    assert_equal 302, last_response.status
    follow_redirect!
    assert_includes last_response.body, 'login' # Redireciona para login
  end
end
