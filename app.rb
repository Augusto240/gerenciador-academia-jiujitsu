require 'sinatra'
require 'pg'
require 'bcrypt'
require 'date'
require 'connection_pool'
require 'logger'
require 'bigdecimal'
require 'rackup'
require 'puma'
require 'rack/csrf'
require 'rack/attack'

# 1. Carregar Configurações
use Rack::MethodOverride

# Configuração de Session Secret segura
# Sinatra exige secret com pelo menos 64 caracteres
session_secret = if ENV['RACK_ENV'] == 'production'
  secret = ENV.fetch('SESSION_SECRET') { raise "SESSION_SECRET não configurada em produção!" }
  # Se o secret for menor que 64 caracteres, expandir usando SHA256
  secret.length >= 64 ? secret : Digest::SHA256.hexdigest(secret + "academia_salt_2024")
else
  ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
end

# Configuração de sessões seguras
set :sessions, {
  key: '_academia_session',
  secret: session_secret,
  httponly: true,
  secure: ENV['RACK_ENV'] == 'production',
  same_site: :lax,
  expire_after: 3600 * 8  # 8 horas
}

# Proteção CSRF
use Rack::Csrf, raise: true, skip: ['POST:/login']

# Rate Limiting com Rack::Attack
use Rack::Attack

# Configurar cache em memória para Rack::Attack (para desenvolvimento/teste)
# Em produção, usar Redis: Rack::Attack.cache.store = Redis.new
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if defined?(ActiveSupport::Cache)

# Fallback para ambiente sem ActiveSupport
class MemoryStore
  def initialize
    @data = {}
    @expires = {}
  end

  def read(key)
    return nil if @expires[key] && @expires[key] < Time.now
    @data[key]
  end

  def write(key, value, options = {})
    @data[key] = value
    @expires[key] = Time.now + (options[:expires_in] || 300) if options[:expires_in]
  end

  def increment(key, amount = 1, options = {})
    @data[key] = (@data[key] || 0) + amount
    @expires[key] = Time.now + (options[:expires_in] || 300) if options[:expires_in]
    @data[key]
  end

  def delete(key)
    @data.delete(key)
    @expires.delete(key)
  end
end

Rack::Attack.cache.store ||= MemoryStore.new

# Limitar tentativas de login: 5 por minuto por IP
Rack::Attack.throttle('login attempts per ip', limit: 5, period: 60) do |req|
  req.ip if req.path == '/login' && req.post?
end

# Limitar requisições gerais: 100 por minuto por IP
Rack::Attack.throttle('requests per ip', limit: 100, period: 60) do |req|
  req.ip
end

# Configuração de Logs
configure do
  log_dir = File.join(File.dirname(__FILE__), 'logs')
  Dir.mkdir(log_dir) unless File.exist?(log_dir)
  
  if ENV['RACK_ENV'] == 'production'
    log_file = File.new(File.join(log_dir, "production.log"), 'a+')
    log_file.sync = true
    set :logger, Logger.new(log_file)
  else
    set :logger, Logger.new(STDOUT)
  end
  enable :logging
end

# 2. Carregar Banco de Dados e Constantes
require_relative 'config/database'

MODALIDADES = ['Jiu Jitsu', 'Muay Thai']
FAIXAS = ['Branca', 'Cinza/Branca', 'Cinza', 'Cinza/Preta', 'Amarela/Branca', 'Amarela', 'Amarela/Preta', 'Laranja/Branca', 'Laranja', 'Laranja/Preta', 'Verde/Branca', 'Verde', 'Verde/Preta', 'Azul', 'Roxa', 'Marrom', 'Preta']
FAIXAS_MUAY_THAI = ['Sem graduação', 'Branca', 'Amarela', 'Laranja', 'Verde', 'Azul', 'Roxa', 'Marrom', 'Preta', 'Preta e Vermelha']
TURMAS = ['Kids 2 a 3 anos', 'Kids', 'Adolescentes/Juvenil', 'Adultos', 'Feminino', 'Master/Sênior']
TURMAS_MUAY_THAI = ['Muay Thai']  # Turma única para Muay Thai

# 3. Carregar Módulos da Aplicação (Ordem importa!)
# Helpers e Validações
require_relative 'app/helpers/validador'

# Services
require_relative 'app/services/pagamento_service'
require_relative 'app/services/aula_service'

# Presenters
require_relative 'app/presenters/base_presenter'
require_relative 'app/presenters/aluno_presenter'
require_relative 'app/presenters/aula_presenter'

# Models
require_relative 'app/models/aluno'
require_relative 'app/models/aula'
require_relative 'app/models/presenca'
require_relative 'app/models/assinatura'
require_relative 'app/models/notificacao'

# ========================================
# HELPERS DO SINATRA
# ========================================
helpers do
  include Validador
  
  def logged_in?
    !!session[:user_id]
  end

  def current_user
    return nil unless logged_in?
    @current_user ||= with_db do |client|
      client.exec_params('SELECT id, nome, email FROM usuarios WHERE id = $1', [session[:user_id]]).first
    end
  end

  def h(text)
    Rack::Utils.escape_html(text.to_s)
  end

  def log_action(acao, dados = {})
    user_info = current_user ? "#{current_user['nome']} (#{current_user['id']})" : "Sistema"
    logger.info("#{user_info} - #{acao} - #{dados.inspect}")
  end
  
  # Helper para usar presenters
  def present(model, klass = nil)
    presenter_class = klass || "#{model.class.name}Presenter".constantize
    presenter_class.new(model)
  rescue NameError
    # Se não encontrar uma classe presenter específica, usar o BasePresenter genérico
    BasePresenter.new(model)
  end
  
  # Helper para formatação de moeda
  def format_currency(value)
    "R$ #{'%.2f' % value.to_f}"
  end
  
  # Helper para formatação de data
  def format_date(date_value, format = '%d/%m/%Y')
    return 'N/A' if date_value.nil? || (date_value.is_a?(String) && date_value.empty?)
    
    begin
      date = date_value.is_a?(String) ? Date.parse(date_value) : date_value
      date.strftime(format)
    rescue
      'Data inválida'
    end
  end
  
  # Helper para gerar data hoje no formato para input
  def today_for_input
    Date.today.strftime('%Y-%m-%d')
  end
  
  # Helper para validar ID numérico
  def valid_id?(id)
    id.to_s.match?(/\A\d+\z/) && id.to_i > 0
  end
  
  # Helper para token CSRF em formulários
  def csrf_tag
    Rack::Csrf.csrf_tag(env)
  end
  
  def csrf_token
    Rack::Csrf.csrf_token(env)
  end
end

# HTTP Security Headers
before do
  headers 'X-Frame-Options' => 'DENY',
          'X-Content-Type-Options' => 'nosniff',
          'X-XSS-Protection' => '1; mode=block',
          'Referrer-Policy' => 'strict-origin-when-cross-origin',
          'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()'
  
  if ENV['RACK_ENV'] == 'production'
    headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
  end
end

# Middleware de autenticação
before do
  pass if ['/login', '/style.css', '/logo.png', '/favicon.ico'].include? request.path_info
  redirect to('/login') unless logged_in?
end

# Tratamento de erros global
error do
  if ENV['RACK_ENV'] != 'production'
    logger.error env['sinatra.error'].message
    logger.error env['sinatra.error'].backtrace.join("\n")
  else
    logger.error "Erro interno: [REDACTED para produção]"
  end
  session[:mensagem_erro] = "Ocorreu um erro inesperado. Por favor tente novamente."
  redirect '/'
end

# ========================================
# ROTAS
# ========================================

# Rotas de autenticação
get('/login') { erb :'auth/login', layout: false }

post '/login' do
  email_digitado = params[:email].to_s.strip.downcase
  senha_digitada = params[:password]
  
  begin
    user = nil
    with_db do |client|
      user = client.exec_params('SELECT * FROM usuarios WHERE LOWER(email) = $1', [email_digitado]).first
    end
    
    if user && BCrypt::Password.new(user['password_digest']) == senha_digitada
      session[:user_id] = user['id']
      logger.info("Login bem-sucedido: #{user['email']} de IP: #{request.ip}")
      redirect to('/')
    else
      logger.warn("Tentativa de login falhou: #{email_digitado} de IP: #{request.ip}")
      session[:mensagem_erro] = "Email ou senha inválidos."
      redirect to('/login')
    end
  rescue => e
    logger.error("Erro no login de IP: #{request.ip} - #{e.message}")
    session[:mensagem_erro] = "Erro ao realizar login. Tente novamente."
    redirect to('/login')
  end
end

# Logout via POST para segurança contra CSRF
post('/logout') do
  log_action("Logout realizado de IP: #{request.ip}")
  session.clear
  session[:mensagem_sucesso] = "Você saiu com segurança."
  redirect to('/login')
end

# Manter GET /logout para compatibilidade, mas redirecionar
get('/logout') do
  redirect to('/login')
end

# Rotas para alunos
get '/' do
  # Aumentar o valor de por_pagina para mostrar todos os alunos
  pagina = params[:pagina]&.to_i || 1
  por_pagina = params[:por_pagina]&.to_i || 1000 
  
  result = Aluno.buscar_com_filtros(
    {
      busca: params[:busca],
      faixa: params[:faixa],
      turma: params[:turma]
    },
    pagina,
    por_pagina
  )
  
  if result.is_a?(Hash)
    @alunos = result[:alunos]
    @pagina_atual = result[:pagina_atual]
    @total_paginas = result[:total_paginas]
    @total_alunos = result[:total]
  else
    @alunos = result
    @total_alunos = @alunos.length
  end
  
  @faixas = FAIXAS
  @faixas_muay_thai = FAIXAS_MUAY_THAI
  @turmas = TURMAS
  @modalidades = MODALIDADES
  erb :index
end

# Rota para exibir página de relatórios
get '/relatorios' do
  @tipos_relatorio = [
    { id: 'frequencia', nome: 'Frequência de Alunos' },
    { id: 'mensalidades', nome: 'Status de Mensalidades' }
  ]
  erb :'relatorios/index'
end

# Rota para gerar relatório específico
get '/relatorios/:tipo' do
  tipo = params['tipo']
  formato = params['formato'] || 'html'
  
  case tipo
  when 'frequencia'
    inicio = params['inicio'] ? Date.parse(params['inicio']) : Date.today.beginning_of_month
    fim = params['fim'] ? Date.parse(params['fim']) : Date.today
    
    @relatorio = Aluno.relatorio_frequencia(inicio, fim)
    @periodo = { inicio: inicio, fim: fim }
    
    if formato == 'csv'
      content_type 'text/csv'
      attachment "relatorio_frequencia_#{inicio.strftime('%Y%m%d')}_#{fim.strftime('%Y%m%d')}.csv"
      
      csv = ["Nome,Presenças,Faltas,Total de Aulas,Taxa de Frequência (%)"]
      @relatorio.each do |r|
        csv << "#{r[:nome]},#{r[:presencas]},#{r[:faltas]},#{r[:total_aulas]},#{r[:taxa_frequencia]}"
      end
      
      return csv.join("\n")
    else
      erb :'relatorios/frequencia'
    end
  when 'mensalidades'
    @relatorio = Assinatura.relatorio_mensalidades
    
    if formato == 'csv'
      content_type 'text/csv'
      attachment "relatorio_mensalidades_#{Date.today.strftime('%Y%m%d')}.csv"
      
      csv = ["Nome,Modalidade,Valor Mensalidade,Status,Último Pagamento,Dias Atraso"]
      @relatorio.each do |r|
        csv << "#{r[:nome]},#{r[:modalidade]},#{r[:valor_mensalidade]},#{r[:status]},#{r[:ultimo_pagamento]},#{r[:dias_atraso]}"
      end
      
      return csv.join("\n")
    else
      erb :'relatorios/mensalidades'
    end
  else
    status 404
    "Relatório não encontrado"
  end
end

post '/alunos' do
  erros = validar_aluno(params)
  
  if erros.any?
    session[:mensagem_erro] = erros.join(", ")
    redirect '/'
    return
  end

  begin
    aluno = Aluno.criar(params)
    
    # Criar assinatura se o aluno não for bolsista
    valor_mensalidade = params['bolsista'] == 'on' ? 0.00 : 70.00
    Assinatura.criar(aluno['id'], valor_mensalidade)

    log_action("Criou aluno", { id: aluno['id'], nome: params['nome'] })
    session[:mensagem_sucesso] = "Aluno cadastrado com sucesso!"
    redirect '/'
  rescue => e
    logger.error("Erro ao cadastrar aluno: #{e.message}")
    session[:mensagem_erro] = "Erro ao cadastrar aluno. Verifique os dados e tente novamente."
    redirect '/'
  end
end

get '/alunos/:id/editar' do
  @aluno = Aluno.buscar_por_id(params['id'])
  redirect '/' if @aluno.nil?

  if @aluno['data_nascimento'] && !@aluno['data_nascimento'].empty?
    begin
      @aluno['data_nascimento'] = Date.parse(@aluno['data_nascimento'])
    rescue
      # Manter o valor original se não for possível converter
    end
  end

  @faixas = FAIXAS
  @faixas_muay_thai = FAIXAS_MUAY_THAI
  @turmas = TURMAS
  @modalidades = MODALIDADES
  erb :editar_aluno
end

# Rota para o formulário de novo aluno
  get '/alunos/novo' do
    @faixas = FAIXAS
    @faixas_muay_thai = FAIXAS_MUAY_THAI
    @turmas = TURMAS
    @modalidades = MODALIDADES
    erb :'alunos/novo'
end

put '/alunos/:id' do
  erros = validar_aluno(params)
  
  if erros.any?
    session[:mensagem_erro] = erros.join(", ")
    redirect "/alunos/#{params['id']}/editar"
    return
  end

  begin
    Aluno.atualizar(params['id'], params)
    log_action("Atualizou aluno", { id: params['id'] })
    session[:mensagem_sucesso] = "Dados do aluno atualizados com sucesso!"
    redirect "/alunos/#{params['id']}"
  rescue => e
    logger.error("Erro ao atualizar aluno: #{e.message}")
    session[:mensagem_erro] = "Erro ao atualizar aluno. Verifique os dados e tente novamente."
    redirect "/alunos/#{params['id']}/editar"
  end
end

delete '/alunos/:id' do
  begin
    aluno = Aluno.buscar_por_id(params['id'])
    Aluno.excluir(params['id'])
    log_action("Excluiu aluno", { id: params['id'], nome: aluno['nome'] })
    session[:mensagem_sucesso] = "Aluno removido com sucesso!"
    redirect '/'
  rescue => e
    logger.error("Erro ao excluir aluno: #{e.message}")
    session[:mensagem_erro] = "Erro ao excluir aluno. Tente novamente."
    redirect "/alunos/#{params['id']}"
  end
end

get '/alunos/:id' do
  @aluno = Aluno.buscar_por_id(params['id'])
  redirect '/' if @aluno.nil?

  @assinatura = Assinatura.buscar_ativa(@aluno['id'])

  if @assinatura
    status_info = Assinatura.verificar_status(@assinatura['id'])
    @status_mensalidade = status_info[:status]
    @cor_status = status_info[:cor]
    @historico_pagamentos = Assinatura.historico_pagamentos(@assinatura['id'])
  else
    @status_mensalidade = "Inativa"
    @cor_status = "status-inativo"
    @historico_pagamentos = []
  end

  @graduacoes = Aluno.obter_graduacoes(@aluno['id'])
  @estatisticas_presenca = Aluno.obter_presencas(@aluno['id'])

  @faixas = FAIXAS
  @faixas_muay_thai = FAIXAS_MUAY_THAI
  @modalidades = MODALIDADES
  erb :'alunos/show'
end

# Rotas para aulas
get '/aulas' do
  @aulas = Aula.todas
  @turmas = TURMAS
  @turmas_muay_thai = TURMAS_MUAY_THAI
  @modalidades = MODALIDADES
  erb :'aulas/index'
end

post '/aulas' do
  erros = validar_aula(params)
  
  if erros.any?
    session[:mensagem_erro] = erros.join(", ")
    redirect "/aulas"
    return
  end

  begin
    result = AulaService.criar_e_inicializar(params)
    
    if result[:success]
      log_action("Criou aula", { id: result[:aula_id], data: params['data_aula'] })
      session[:mensagem_sucesso] = result[:message]
      redirect "/aulas/#{result[:aula_id]}"
    else
      session[:mensagem_erro] = result[:message]
      redirect "/aulas"
    end
  rescue => e
    logger.error("Erro ao criar aula: #{e.message}")
    session[:mensagem_erro] = "Erro ao criar aula. Verifique os dados e tente novamente."
    redirect "/aulas"
  end
end

# Rota para o formulário de nova aula
get '/aulas/nova' do
  @turmas = TURMAS
  @turmas_muay_thai = TURMAS_MUAY_THAI
  @modalidades = MODALIDADES
  erb :'aulas/nova'
end

get '/aulas/:id' do
  @aula = Aula.buscar_por_id(params['id'])
  redirect '/aulas' if @aula.nil?
  
  @lista_presenca = Aula.lista_presenca(@aula['id'])
  erb :'aulas/show'
end

# Rota para marcar notificação como lida
get '/notificacoes/:id/marcar-como-lida' do
  Notificacao.marcar_como_lida(params['id'])
  redirect back
end

get '/gerar-notificacoes' do
  if logged_in? && current_user['admin'] == 't'
    Notificacao.gerar_notificacoes_automaticas
    redirect back
  else
    status 403
    "Acesso negado"
  end
end

post '/aulas/:id/presencas' do
  begin
    result = AulaService.atualizar_presencas(params['id'], params['presentes'] || [])
    
    if result[:success]
      log_action("Atualizou presenças", { 
        aula_id: params['id'], 
        presentes: result[:presencas_atualizadas]
      })
      session[:mensagem_sucesso] = result[:message]
    else
      session[:mensagem_erro] = result[:message]
    end
    
    redirect "/aulas/#{params['id']}"
  rescue => e
    logger.error("Erro ao atualizar presenças: #{e.message}")
    session[:mensagem_erro] = "Erro ao atualizar presenças. Tente novamente."
    redirect "/aulas/#{params['id']}"
  end
end

# Rotas para pagamentos
post '/pagamentos' do
  erros = validar_pagamento(params)
  
  if erros.any?
    session[:mensagem_erro] = erros.join(", ")
    redirect "/alunos/#{params['aluno_id']}"
    return
  end

  begin
    result = PagamentoService.registrar_pagamento(
      params['assinatura_id'],
      params['aluno_id'],
      params['valor_pago'], 
      params['data_pagamento']
    )
    
    if result[:success]
      log_action("Registrou pagamento", { 
        aluno_id: params['aluno_id'], 
        valor: params['valor_pago'],
        payment_id: result[:payment_id]
      })
      session[:mensagem_sucesso] = result[:message]
    else
      session[:mensagem_erro] = result[:message]
    end
    
    redirect "/alunos/#{params['aluno_id']}"
  rescue => e
    logger.error("Erro ao registrar pagamento: #{e.message}")
    session[:mensagem_erro] = "Erro ao registrar pagamento. Verifique os dados e tente novamente."
    redirect "/alunos/#{params['aluno_id']}"
  end
end

# Rotas para graduações
post '/graduacoes' do
  erros = validar_graduacao(params)
  
  if erros.any?
    session[:mensagem_erro] = erros.join(", ")
    redirect "/alunos/#{params['aluno_id']}"
    return
  end
  
  begin
    Aluno.registrar_graduacao(
      params['aluno_id'], 
      params['faixa'], 
      params['data_graduacao']
    )
    log_action("Registrou graduação", { 
      aluno_id: params['aluno_id'], 
      faixa: params['faixa'] 
    })
    session[:mensagem_sucesso] = "Graduação registrada com sucesso!"
    redirect "/alunos/#{params['aluno_id']}"
  rescue => e
    logger.error("Erro ao registrar graduação: #{e.message}")
    session[:mensagem_erro] = "Erro ao registrar graduação. Verifique os dados e tente novamente."
    redirect "/alunos/#{params['aluno_id']}"
  end
end

# Adicionar rota para dashboard em app.rb
get '/dashboard' do
  # Estatísticas básicas
  @total_alunos = Aluno.total
  @alunos_ativos = Aluno.buscar_com_filtros.count
  @total_aulas_mes = Aula.total_no_mes_atual
  @total_presencas_mes = Presenca.total_no_mes_atual
  
  # Dados para gráficos
  @historico_presencas = Presenca.historico_ultimos_meses
  
  # Alunos com aniversário no mês
  @aniversariantes = Aluno.aniversariantes_do_mes
  
  # Mensalidades
  @mensalidades_atrasadas = Assinatura.contar_por_status("Atrasado")
  @mensalidades_em_dia = Assinatura.contar_por_status("Em Dia")
  
  Notificacao.gerar_notificacoes_automaticas
  erb :dashboard
end