require 'sinatra'
require 'pg'
require 'bcrypt'
require 'date'
require 'connection_pool'
require 'logger'
require 'bigdecimal'
require 'rackup'
require 'puma'

# 1. Carregar Configurações
use Rack::MethodOverride
enable :sessions

session_secret = ENV.fetch('SESSION_SECRET') { "uma_chave_super_secreta_e_aleatoria_para_desenvolvimento_muito_muito_longa_e_segura_12345678901234" }
if session_secret.length < 64
  session_secret = session_secret.ljust(64, 'x')
end
set :session_secret, session_secret

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
  email_digitado = params[:email]
  senha_digitada = params[:password]
  
  begin
    user = nil
    with_db do |client|
      user = client.exec_params('SELECT * FROM usuarios WHERE email = $1', [email_digitado]).first
    end
    
    if user && BCrypt::Password.new(user['password_digest']) == senha_digitada
      session[:user_id] = user['id']
      logger.info("Login bem-sucedido: #{user['email']}")
      redirect to('/')
    else
      logger.warn("Tentativa de login falhou: #{email_digitado}")
      session[:mensagem_erro] = "Email ou senha inválidos."
      redirect to('/login')
    end
  rescue => e
    logger.error("Erro no login: #{e.message}")
    session[:mensagem_erro] = "Erro ao realizar login. Tente novamente."
    redirect to('/login')
  end
end

get('/logout') do
  log_action("Logout realizado")
  session.clear
  session[:mensagem_sucesso] = "Você saiu com segurança."
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