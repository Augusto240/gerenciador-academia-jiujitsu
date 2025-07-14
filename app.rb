require 'sinatra'
require 'pg'
require 'bcrypt'
require 'date'
require 'connection_pool'
require 'logger'

use Rack::MethodOverride
enable :sessions
set :session_secret, ENV.fetch('SESSION_SECRET') { "uma_chave_super_secreta_e_aleatoria_para_desenvolvimento" }

# Constantes globais
FAIXAS = ['Branca', 'Cinza/Branca', 'Cinza', 'Cinza/Preta', 'Amarela/Branca', 'Amarela', 'Amarela/Preta', 'Laranja/Branca', 'Laranja', 'Laranja/Preta', 'Verde/Branca', 'Verde', 'Verde/Preta', 'Azul', 'Roxa', 'Marrom', 'Preta']
TURMAS = ['Kids 2 a 3 anos', 'Kids', 'Adolescentes/Juvenil', 'Adultos', 'Feminino', 'Master/Sênior']

# Configuração de ambiente e banco de dados
configure do
  # Configuração de logs
  set :logger, Logger.new(ENV['RACK_ENV'] == 'production' ? 'logs/production.log' : STDOUT)
  enable :logging
end

# Pool de conexões para o banco de dados
DB_POOL = ConnectionPool.new(size: 5, timeout: 5) do
  if ENV['DATABASE_URL']
    PG.connect(ENV['DATABASE_URL'])
  else
    PG.connect(
      host: ENV.fetch('DATABASE_HOST', 'db'),
      user: ENV.fetch('DATABASE_USER', 'jiujitsu_user'),
      password: ENV.fetch('DATABASE_PASSWORD', 'senha_forte_123'),
      dbname: ENV.fetch('DATABASE_NAME', 'academia_jiujitsu_dev')
    )
  end
end

# Helper para usar o pool de conexões
def with_db
  DB_POOL.with do |conn|
    begin
      yield conn
    rescue PG::Error => e
      logger.error "Erro de banco de dados: #{e.message}"
      raise
    end
  end
end

# Módulo de validação
module Validador
  def validar_aluno(params)
    erros = []
    
    erros << "Nome é obrigatório" if params['nome'].to_s.strip.empty?
    erros << "Nome deve ter entre 2 e 100 caracteres" if params['nome'].to_s.length < 2 || params['nome'].to_s.length > 100
    erros << "Faixa inválida" unless FAIXAS.include?(params['cor_faixa'])
    erros << "Turma inválida" unless TURMAS.include?(params['turma'])
    
    if params['data_nascimento'] && !params['data_nascimento'].empty?
      begin
        data_nasc = Date.parse(params['data_nascimento'])
        erros << "Data de nascimento não pode ser futura" if data_nasc > Date.today
        erros << "Data de nascimento inválida (muito antiga)" if data_nasc < Date.new(1900, 1, 1)
      rescue Date::Error
        erros << "Data de nascimento em formato inválido"
      end
    end
    
    erros
  end

  def validar_aula(params)
    erros = []
    
    erros << "Data da aula é obrigatória" if params['data_aula'].to_s.strip.empty?
    
    if params['data_aula'] && !params['data_aula'].empty?
      begin
        data_aula = Date.parse(params['data_aula'])
        erros << "Data da aula não pode ser futura" if data_aula > Date.today
      rescue Date::Error
        erros << "Data da aula em formato inválido"
      end
    end
    
    erros << "Turma inválida" if !params['turma'].empty? && !TURMAS.include?(params['turma'])
    
    erros
  end

  def validar_pagamento(params)
    erros = []
    
    erros << "Valor do pagamento é obrigatório" if params['valor_pago'].to_s.strip.empty?
    erros << "Data do pagamento é obrigatória" if params['data_pagamento'].to_s.strip.empty?
    
    if params['valor_pago']
      begin
        valor = Float(params['valor_pago'])
        erros << "Valor do pagamento deve ser positivo" if valor <= 0
      rescue ArgumentError
        erros << "Valor do pagamento inválido"
      end
    end
    
    if params['data_pagamento'] && !params['data_pagamento'].empty?
      begin
        Date.parse(params['data_pagamento'])
      rescue Date::Error
        erros << "Data do pagamento em formato inválido"
      end
    end
    
    erros
  end
end

# Classe Aluno
class Aluno
  def self.todos
    with_db do |client|
      client.exec("SELECT * FROM alunos ORDER BY nome").to_a
    end
  end

  def self.buscar_por_id(id)
    with_db do |client|
      client.exec_params("SELECT * FROM alunos WHERE id = $1", [id]).first
    end
  end

  def self.buscar_com_filtros(filtros = {})
    with_db do |client|
      query = "SELECT id, nome, data_nascimento, cor_faixa, turma FROM alunos"
      conditions = []
      params_list = []
      param_count = 1

      if filtros[:busca] && !filtros[:busca].empty?
        conditions << "nome ILIKE $#{param_count}"
        params_list << "%#{filtros[:busca]}%"
        param_count += 1
      end

      if filtros[:faixa] && !filtros[:faixa].empty?
        conditions << "cor_faixa = $#{param_count}"
        params_list << filtros[:faixa]
        param_count += 1
      end

      if filtros[:turma] && !filtros[:turma].empty?
        conditions << "turma = $#{param_count}"
        params_list << filtros[:turma]
        param_count += 1
      end

      query += " WHERE #{conditions.join(' AND ')}" unless conditions.empty?
      query += " ORDER BY nome ASC"

      result = client.exec_params(query, params_list).to_a
      
      # Calcular idade para cada aluno
      result.each do |aluno|
        hoje = Date.today
        data_nasc_str = aluno['data_nascimento']
        if data_nasc_str && !data_nasc_str.empty?
          begin
            data_nasc_obj = Date.parse(data_nasc_str)
            idade = hoje.year - data_nasc_obj.year
            idade -= 1 if hoje < Date.new(hoje.year, data_nasc_obj.month, data_nasc_obj.day)
            aluno['idade'] = idade
          rescue Date::Error
            aluno['idade'] = 'Inválida'
          end
        else
          aluno['idade'] = 'N/A'
        end
      end
      
      result
    end
  end

  def self.total
    with_db do |client|
      result = client.exec("SELECT COUNT(id) AS count FROM alunos")
      result.first['count'].to_i
    end
  end

  def self.criar(params)
    with_db do |client|
      client.exec <<~SQL
        SELECT setval(
          pg_get_serial_sequence('alunos', 'id'),
          (SELECT COALESCE(MAX(id), 0) FROM alunos)
        );
      SQL

      bolsista = params['bolsista'] == 'on'

      query = <<~SQL
        INSERT INTO alunos(
          nome, data_nascimento, cor_faixa, turma,
          bolsista, saude_problema, saude_medicacao,
          saude_lesao, saude_substancia
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id
      SQL

      params_list = [
        params['nome'],
        params['data_nascimento'].empty? ? nil : params['data_nascimento'],
        params['cor_faixa'],
        params['turma'],
        bolsista,
        params['saude_problema'],
        params['saude_medicacao'],
        params['saude_lesao'],
        params['saude_substancia']
      ]

      result = client.exec_params(query, params_list)
      result.first
    end
  end

  def self.atualizar(id, params)
    with_db do |client|
      bolsista = params['bolsista'] == 'on'
      
      query = <<~SQL
        UPDATE alunos SET
          nome = $1,
          data_nascimento = $2,
          cor_faixa = $3,
          turma = $4,
          bolsista = $5,
          saude_problema = $6,
          saude_medicacao = $7,
          saude_lesao = $8,
          saude_substancia = $9
        WHERE id = $10
        RETURNING id
      SQL
      
      params_list = [
        params['nome'],
        params['data_nascimento'].empty? ? nil : params['data_nascimento'],
        params['cor_faixa'],
        params['turma'],
        bolsista,
        params['saude_problema'],
        params['saude_medicacao'],
        params['saude_lesao'],
        params['saude_substancia'],
        id
      ]

      result = client.exec_params(query, params_list)
      result.first
    end
  end

  def self.excluir(id)
    with_db do |client|
      client.exec_params("DELETE FROM alunos WHERE id = $1 RETURNING id", [id]).first
    end
  end

  def self.registrar_graduacao(aluno_id, faixa, data_graduacao)
    with_db do |client|
      # Registrar graduação
      client.exec_params(
        "INSERT INTO graduacoes(aluno_id, faixa, data_graduacao) VALUES ($1, $2, $3) RETURNING id",
        [aluno_id, faixa, data_graduacao]
      )
      
      # Atualizar faixa atual do aluno
      client.exec_params(
        "UPDATE alunos SET cor_faixa = $1 WHERE id = $2",
        [faixa, aluno_id]
      )
    end
  end

  def self.obter_graduacoes(aluno_id)
    with_db do |client|
      client.exec_params(
        "SELECT * FROM graduacoes WHERE aluno_id = $1 ORDER BY data_graduacao DESC",
        [aluno_id]
      ).to_a
    end
  end

  def self.obter_presencas(aluno_id)
    with_db do |client|
      total_aulas = client.exec("SELECT COUNT(id) as count FROM aulas").first['count'].to_i
      presencas = client.exec_params(
        "SELECT COUNT(id) as count FROM presencas WHERE aluno_id = $1 AND presente = TRUE",
        [aluno_id]
      ).first['count'].to_i
      
      {
        total_aulas: total_aulas,
        presencas: presencas,
        faltas: total_aulas - presencas
      }
    end
  end
end

# Classe Aula
class Aula
  def self.todas
    with_db do |client|
      client.exec("SELECT * FROM aulas ORDER BY data_aula DESC").to_a
    end
  end

  def self.buscar_por_id(id)
    with_db do |client|
      client.exec_params("SELECT * FROM aulas WHERE id = $1", [id]).first
    end
  end

  def self.criar(params)
    with_db do |client|
      turma_aula = params['turma'].empty? ? nil : params['turma']
      todas_turmas = params['todas_turmas'] == 'on'

      result = client.exec_params(
        "INSERT INTO aulas (data_aula, turma, descricao) VALUES ($1, $2, $3) RETURNING id",
        [params['data_aula'], turma_aula, params['descricao']]
      )
      aula_id = result.first['id']

      # Inicializar lista de presença
      if todas_turmas
        alunos_q = client.exec("SELECT id FROM alunos")
      elsif turma_aula
        alunos_q = client.exec_params("SELECT id FROM alunos WHERE turma = $1", [turma_aula])
      else
        alunos_q = client.exec("SELECT id FROM alunos")
      end

      # Inserir presença inicial (todos ausentes)
      alunos_q.each do |a|
        client.exec_params(
          "INSERT INTO presencas (aula_id, aluno_id, presente) VALUES ($1, $2, FALSE) ON CONFLICT (aluno_id, aula_id) DO NOTHING",
          [aula_id, a['id']]
        )
      end

      aula_id
    end
  end

  def self.lista_presenca(aula_id)
    with_db do |client|
      client.exec_params(
        "SELECT p.aluno_id AS id, a.nome, p.presente FROM presencas p JOIN alunos a ON p.aluno_id = a.id WHERE p.aula_id = $1 ORDER BY a.nome",
        [aula_id]
      ).to_a
    end
  end

  def self.atualizar_presencas(aula_id, presentes = [])
    with_db do |client|
      # Marcar todos como ausentes primeiro
      client.exec_params("UPDATE presencas SET presente = FALSE WHERE aula_id = $1", [aula_id])
      
      # Marcar os presentes
      presentes.each do |aluno_id|
        client.exec_params(
          "UPDATE presencas SET presente = TRUE WHERE aula_id = $1 AND aluno_id = $2",
          [aula_id, aluno_id]
        )
      end
    end
  end
end

# Classe Assinatura
class Assinatura
  def self.buscar_ativa(aluno_id)
    with_db do |client|
      client.exec_params(
        "SELECT * FROM assinaturas WHERE aluno_id = $1 AND status = 'ativa'",
        [aluno_id]
      ).first
    end
  end

  def self.criar(aluno_id, valor_mensalidade = 70.00)
    with_db do |client|
      client.exec_params(
        "INSERT INTO assinaturas(aluno_id, plano_id, valor_mensalidade, status)
         VALUES ($1, 1, $2, 'ativa') RETURNING id",
        [aluno_id, valor_mensalidade]
      ).first
    end
  end

  def self.historico_pagamentos(assinatura_id)
    with_db do |client|
      client.exec_params(
        "SELECT * FROM pagamentos WHERE assinatura_id = $1 ORDER BY data_pagamento DESC",
        [assinatura_id]
      ).to_a
    end
  end

  def self.registrar_pagamento(assinatura_id, valor_pago, data_pagamento)
    with_db do |client|
      client.exec_params(
        "INSERT INTO pagamentos(assinatura_id, valor_pago, data_pagamento) VALUES ($1, $2, $3) RETURNING id",
        [assinatura_id, valor_pago, data_pagamento]
      ).first
    end
  end

  def self.verificar_status(assinatura_id)
    with_db do |client|
      assinatura = client.exec_params(
        "SELECT * FROM assinaturas WHERE id = $1", 
        [assinatura_id]
      ).first

      return { status: "Inativa", cor: "status-inativo" } unless assinatura

      ultimo_pag = client.exec_params(
        "SELECT data_pagamento FROM pagamentos WHERE assinatura_id = $1 ORDER BY data_pagamento DESC LIMIT 1",
        [assinatura_id]
      ).first

      if ultimo_pag
        vencimento = Date.parse(ultimo_pag['data_pagamento']) + 30
        if Date.today > vencimento
          { status: "Atrasado", cor: "status-atrasado" }
        else
          { status: "Em Dia", cor: "status-em-dia" }
        end
      else
        { status: "Pendente", cor: "status-pendente" }
      end
    end
  end
end

# Helpers para as views
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
    logger.info("#{current_user['nome']} (#{current_user['id']}) - #{acao} - #{dados.inspect}")
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
  @alunos = Aluno.buscar_com_filtros(
    busca: params[:busca],
    faixa: params[:faixa],
    turma: params[:turma]
  )
  
  @total_alunos = Aluno.total
  @faixas = FAIXAS
  @turmas = TURMAS
  erb :index
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
  @turmas = TURMAS
  erb :editar_aluno
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
  erb :'alunos/show'
end

# Rotas para aulas
get '/aulas' do
  @aulas = Aula.todas
  @turmas = TURMAS
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
    aula_id = Aula.criar(params)
    log_action("Criou aula", { id: aula_id, data: params['data_aula'] })
    session[:mensagem_sucesso] = "Aula criada com sucesso!"
    redirect "/aulas/#{aula_id}"
  rescue => e
    logger.error("Erro ao criar aula: #{e.message}")
    session[:mensagem_erro] = "Erro ao criar aula. Verifique os dados e tente novamente."
    redirect "/aulas"
  end
end

get '/aulas/:id' do
  @aula = Aula.buscar_por_id(params['id'])
  redirect '/aulas' if @aula.nil?
  
  @lista_presenca = Aula.lista_presenca(@aula['id'])
  erb :'aulas/show'
end

post '/aulas/:id/presencas' do
  begin
    Aula.atualizar_presencas(params['id'], params['presentes'] || [])
    log_action("Atualizou presenças", { aula_id: params['id'], presentes: (params['presentes'] || []).count })
    session[:mensagem_sucesso] = "Lista de presença atualizada!"
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
    Assinatura.registrar_pagamento(
      params['assinatura_id'], 
      params['valor_pago'], 
      params['data_pagamento']
    )
    log_action("Registrou pagamento", { 
      aluno_id: params['aluno_id'], 
      valor: params['valor_pago'] 
    })
    session[:mensagem_sucesso] = "Pagamento registrado com sucesso!"
    redirect "/alunos/#{params['aluno_id']}"
  rescue => e
    logger.error("Erro ao registrar pagamento: #{e.message}")
    session[:mensagem_erro] = "Erro ao registrar pagamento. Verifique os dados e tente novamente."
    redirect "/alunos/#{params['aluno_id']}"
  end
end

# Rotas para graduações
post '/graduacoes' do
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