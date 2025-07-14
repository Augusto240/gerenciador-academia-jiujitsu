require 'sinatra'
require 'pg'
require 'bcrypt'
require 'date'
require 'connection_pool'
require 'logger'
require 'bigdecimal'  # Mantendo esta gem também
require 'rackup'
require 'puma'

use Rack::MethodOverride
enable :sessions
set :session_secret, ENV.fetch('SESSION_SECRET') { "uma_chave_super_secreta_e_aleatoria_para_desenvolvimento_muito_muito_longa_e_segura_12345678901234" }

# ========================================
# CONSTANTES E CONFIGURAÇÃO
# ========================================

FAIXAS = ['Branca', 'Cinza/Branca', 'Cinza', 'Cinza/Preta', 'Amarela/Branca', 'Amarela', 'Amarela/Preta', 'Laranja/Branca', 'Laranja', 'Laranja/Preta', 'Verde/Branca', 'Verde', 'Verde/Preta', 'Azul', 'Roxa', 'Marrom', 'Preta']
TURMAS = ['Kids 2 a 3 anos', 'Kids', 'Adolescentes/Juvenil', 'Adultos', 'Feminino', 'Master/Sênior']
DB_POOL_SIZE = ENV.fetch('DB_POOL_SIZE', 10).to_i

# Configuração de ambiente
configure do
  # Diretório de logs
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

# Pool de conexões para o banco de dados (otimizado)
DB_POOL = ConnectionPool.new(size: DB_POOL_SIZE, timeout: 5) do
  connection_params = if ENV['DATABASE_URL']
    ENV['DATABASE_URL']
  else
    {
      host: ENV.fetch('DATABASE_HOST', 'db'),
      user: ENV.fetch('DATABASE_USER', 'jiujitsu_user'),
      password: ENV.fetch('DATABASE_PASSWORD', 'senha_forte_123'),
      dbname: ENV.fetch('DATABASE_NAME', 'academia_jiujitsu_dev'),
      # Parâmetros que melhoram a performance
      connect_timeout: 5,
      keepalives: 1,
      keepalives_idle: 30,
      keepalives_interval: 10,
      keepalives_count: 3
    }
  end
  
  PG.connect(connection_params)
end

# Helper para usar o pool de conexões
def with_db
  DB_POOL.with do |conn|
    begin
      yield conn
    rescue PG::Error => e
      # Usar STDERR diretamente em vez de tentar acessar settings.logger
      STDERR.puts "Erro de banco de dados: #{e.message}"
      raise
    end
  end
end

# ========================================
# APRESENTAÇÃO (PRESENTERS)
# ========================================

# Extensões para a classe Date (já que não temos ActiveSupport)
class Date
  def self.beginning_of_month(date = Date.today)
    Date.new(date.year, date.month, 1)
  end
  
  def self.end_of_month(date = Date.today)
    # Calcula o último dia do mês (próximo mês, dia 1, -1 dia)
    next_month = date.month == 12 ? Date.new(date.year + 1, 1, 1) : Date.new(date.year, date.month + 1, 1)
    next_month - 1
  end
  
  def beginning_of_month
    Date.beginning_of_month(self)
  end
  
  def end_of_month
    Date.end_of_month(self)
  end
end


# BasePresenter - Base para os outros presenters
class BasePresenter
  def initialize(model)
    @model = model
  end
  
  def method_missing(method, *args, &block)
    if @model.respond_to?(:[]) && @model.has_key?(method.to_s)
      @model[method.to_s]
    elsif @model.respond_to?(method)
      @model.send(method, *args, &block)
    else
      super
    end
  end
  
  def respond_to_missing?(method, include_private = false)
    (@model.respond_to?(:[]) && @model.has_key?(method.to_s)) || 
    @model.respond_to?(method, include_private) || 
    super
  end
  
  def format_date(date_value, format = '%d/%m/%Y')
    return 'N/A' if date_value.nil? || (date_value.is_a?(String) && date_value.empty?)
    
    begin
      date = date_value.is_a?(String) ? Date.parse(date_value) : date_value
      date.strftime(format)
    rescue
      'Data inválida'
    end
  end
  
  def date_for_input(date_value)
    return Date.today.strftime('%Y-%m-%d') unless date_value
    
    begin
      date = date_value.is_a?(String) ? Date.parse(date_value) : date_value
      date.strftime('%Y-%m-%d')
    rescue
      Date.today.strftime('%Y-%m-%d')
    end
  end
  
  def format_currency(value)
    "R$ #{'%.2f' % value.to_f}"
  end
end

# AlunoPresenter - Para apresentação dos dados de alunos
class AlunoPresenter < BasePresenter
  def status
    @model['bolsista'] == 't' || @model['bolsista'] == true ? 'Bolsista' : 'Pagante'
  end
  
  def data_nascimento_formatada
    format_date(@model['data_nascimento'])
  end
  
  def data_hoje_para_input
    Date.today.strftime('%Y-%m-%d')
  end
  
  def idade
    return 'N/A' if @model['data_nascimento'].nil? || @model['data_nascimento'].to_s.empty?
    
    begin
      data_nasc = Date.parse(@model['data_nascimento'].to_s)
      hoje = Date.today
      idade = hoje.year - data_nasc.year
      idade -= 1 if hoje < Date.new(hoje.year, data_nasc.month, data_nasc.day)
      idade.to_s
    rescue
      'N/A'
    end
  end
  
  def problema_saude
    (@model['saude_problema'] && !@model['saude_problema'].empty?) ? @model['saude_problema'] : 'Não informado'
  end
  
  def uso_medicacao
    (@model['saude_medicacao'] && !@model['saude_medicacao'].empty?) ? @model['saude_medicacao'] : 'Não informado'
  end
  
  def historico_lesoes
    (@model['saude_lesao'] && !@model['saude_lesao'].empty?) ? @model['saude_lesao'] : 'Não informado'
  end
  
  def uso_substancias
    (@model['saude_substancia'] && !@model['saude_substancia'].empty?) ? @model['saude_substancia'] : 'Não informado'
  end
  
  def possui_graduacoes?(graduacoes)
    graduacoes && graduacoes.any?
  end
  
  def formatar_graduacao(graduacao)
    data = format_date(graduacao['data_graduacao'])
    "#{graduacao['faixa']} em #{data}"
  end
end

# AulaPresenter - Para apresentação dos dados de aulas
class AulaPresenter < BasePresenter
  def data_formatada
    format_date(@model['data_aula'])
  end
  
  def descricao
    @model['descricao'].to_s.empty? ? '—' : @model['descricao']
  end
  
  def turma_formatada
    @model['turma'].to_s.empty? ? '—' : @model['turma']
  end
  
  def aluno_presente?(aluno)
    aluno['presente'] == 't' || aluno['presente'] == true
  end
end

# ========================================
# SERVIÇOS (SERVICES)
# ========================================

# Serviço para gerenciamento de pagamentos
module PagamentoService
  def self.registrar_pagamento(assinatura_id, aluno_id, valor_pago, data_pagamento)
    result = { success: false, message: "", payment_id: nil }

    begin
      # Validações básicas (além das feitas no controlador)
      if valor_pago.to_f <= 0
        result[:message] = "Valor do pagamento deve ser positivo"
        return result
      end

      # Registrar pagamento
      with_db do |client|
        payment_record = client.exec_params(
          "INSERT INTO pagamentos(assinatura_id, valor_pago, data_pagamento) 
           VALUES ($1, $2, $3) RETURNING id",
          [assinatura_id, valor_pago, data_pagamento]
        ).first

        # Atualizar status da assinatura se necessário
        client.exec_params(
          "UPDATE assinaturas SET status = 'ativa' WHERE id = $1 AND status != 'ativa'",
          [assinatura_id]
        )

        result[:success] = true
        result[:message] = "Pagamento registrado com sucesso!"
        result[:payment_id] = payment_record['id']
      end
    rescue PG::Error => e
      result[:message] = "Erro ao registrar pagamento: #{e.message}"
    rescue => e
      result[:message] = "Erro inesperado: #{e.message}"
    end

    result
  end
end

# Serviço para gerenciamento de aulas e presenças
module AulaService
  def self.criar_e_inicializar(params)
    result = { success: false, message: "", aula_id: nil }
    
    begin
      with_db do |client|
        turma_aula = params['turma'].empty? ? nil : params['turma']
        todas_turmas = params['todas_turmas'] == 'on'

        insert_result = client.exec_params(
          "INSERT INTO aulas (data_aula, turma, descricao) VALUES ($1, $2, $3) RETURNING id",
          [params['data_aula'], turma_aula, params['descricao']]
        ).first
        aula_id = insert_result['id']

        # Selecionar alunos para a lista de presença
        alunos_q = if todas_turmas
          client.exec("SELECT id FROM alunos")
        elsif turma_aula
          client.exec_params("SELECT id FROM alunos WHERE turma = $1", [turma_aula])
        else
          client.exec("SELECT id FROM alunos")
        end

        # Inicializar presenças em massa
        alunos_q.each do |a|
          client.exec_params(
            "INSERT INTO presencas (aula_id, aluno_id, presente) VALUES ($1, $2, FALSE) ON CONFLICT (aluno_id, aula_id) DO NOTHING",
            [aula_id, a['id']]
          )
        end
        
        result[:success] = true
        result[:message] = "Aula criada com sucesso!"
        result[:aula_id] = aula_id
      end
    rescue PG::Error => e
      result[:message] = "Erro de banco de dados: #{e.message}"
    rescue => e
      result[:message] = "Erro inesperado: #{e.message}"
    end
    
    result
  end
  
  def self.atualizar_presencas(aula_id, presentes = [])
    result = { success: false, message: "", presencas_atualizadas: 0 }
    
    begin
      with_db do |client|
        # Marcar todos como ausentes primeiro
        client.exec_params("UPDATE presencas SET presente = FALSE WHERE aula_id = $1", [aula_id])
        
        # Contar quantos alunos serão marcados como presentes
        count = presentes.length
        
        # Marcar os presentes
        presentes.each do |aluno_id|
          client.exec_params(
            "UPDATE presencas SET presente = TRUE WHERE aula_id = $1 AND aluno_id = $2",
            [aula_id, aluno_id]
          )
        end
        
        result[:success] = true
        result[:message] = "Lista de presença atualizada com sucesso!"
        result[:presencas_atualizadas] = count
      end
    rescue => e
      result[:message] = "Erro ao atualizar presenças: #{e.message}"
    end
    
    result
  end
end

# ========================================
# VALIDAÇÃO
# ========================================

module Validador
  def validar_aluno(params)
    erros = []
    
    # Validações básicas
    erros << "Nome é obrigatório" if params['nome'].to_s.strip.empty?
    erros << "Nome deve ter entre 2 e 100 caracteres" if params['nome'].to_s.length < 2 || params['nome'].to_s.length > 100
    erros << "Faixa inválida" unless FAIXAS.include?(params['cor_faixa'])
    erros << "Turma inválida" unless TURMAS.include?(params['turma'])
    
    # Validação de data de nascimento
    if params['data_nascimento'] && !params['data_nascimento'].empty?
      begin
        data_nasc = Date.parse(params['data_nascimento'])
        idade = calcular_idade(data_nasc)
        
        erros << "Data de nascimento não pode ser futura" if data_nasc > Date.today
        erros << "Data de nascimento inválida (muito antiga)" if data_nasc < Date.new(1900, 1, 1)
        erros << "Idade mínima para cadastro é 2 anos" if idade < 2
        erros << "Idade máxima para cadastro é 100 anos" if idade > 100
      rescue Date::Error
        erros << "Data de nascimento em formato inválido"
      end
    end
    
    # Validação de campos de saúde (opcional)
    ['saude_problema', 'saude_medicacao', 'saude_lesao', 'saude_substancia'].each do |campo|
      if params[campo] && params[campo].length > 500
        erros << "Campo '#{campo.gsub('saude_', '')}' não deve exceder 500 caracteres"
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
        erros << "Data da aula muito antiga" if data_aula < Date.today - 365  # Não permitir datas de mais de 1 ano atrás
      rescue Date::Error
        erros << "Data da aula em formato inválido"
      end
    end
    
    erros << "Turma inválida" if !params['turma'].empty? && !TURMAS.include?(params['turma'])
    
    if params['descricao'] && params['descricao'].length > 255
      erros << "Descrição não deve exceder 255 caracteres"
    end
    
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
        data_pag = Date.parse(params['data_pagamento'])
        erros << "Data do pagamento não pode ser futura" if data_pag > Date.today
        erros << "Data do pagamento muito antiga" if data_pag < Date.today - 365*2  # Limitar a 2 anos atrás
      rescue Date::Error
        erros << "Data do pagamento em formato inválido"
      end
    end
    
    erros
  end
  
  def validar_graduacao(params)
    erros = []
    
    erros << "Faixa é obrigatória" if params['faixa'].to_s.strip.empty?
    erros << "Data da graduação é obrigatória" if params['data_graduacao'].to_s.strip.empty?
    
    if params['faixa'] && !FAIXAS.include?(params['faixa'])
      erros << "Faixa inválida"
    end
    
    if params['data_graduacao'] && !params['data_graduacao'].empty?
      begin
        data_grad = Date.parse(params['data_graduacao'])
        erros << "Data da graduação não pode ser futura" if data_grad > Date.today
        erros << "Data da graduação muito antiga" if data_grad < Date.today - 365*10  # Limitar a 10 anos atrás
      rescue Date::Error
        erros << "Data da graduação em formato inválido"
      end
    end
    
    erros
  end
  
  def calcular_idade(data_nasc)
    hoje = Date.today
    idade = hoje.year - data_nasc.year
    idade -= 1 if hoje < Date.new(hoje.year, data_nasc.month, data_nasc.day)
    idade
  end
end

# ========================================
# MODELOS (MODELS)
# ========================================

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

  def self.buscar_com_filtros(filtros = {}, pagina = 1, por_pagina = 20)
    pagina = [pagina.to_i, 1].max
    offset = (pagina - 1) * por_pagina
    
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
      
      # Adicionar paginação se solicitado
      if por_pagina > 0
        query += " LIMIT $#{param_count} OFFSET $#{param_count + 1}"
        params_list << por_pagina
        params_list << offset
      end

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
      
      # Se paginação estiver ativa, contar total
      if por_pagina > 0
        count_query = "SELECT COUNT(*) AS total FROM alunos"
        count_query += " WHERE #{conditions.join(' AND ')}" unless conditions.empty?
        total = client.exec_params(count_query, params_list[0..-3] || []).first['total'].to_i
        
        return {
          alunos: result, 
          total: total,
          pagina_atual: pagina,
          total_paginas: (total.to_f / por_pagina).ceil
        }
      else
        return result
      end
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
        params['nome'].strip,
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
        params['nome'].strip,
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

  def self.aniversariantes_do_mes
  mes_atual = Date.today.month
  with_db do |client|
    client.exec_params(
      "SELECT id, nome, data_nascimento FROM alunos 
       WHERE EXTRACT(MONTH FROM data_nascimento) = $1
       ORDER BY EXTRACT(DAY FROM data_nascimento)",
      [mes_atual]
    ).to_a
    end
  end

def self.relatorio_frequencia(inicio_periodo = nil, fim_periodo = nil)
  inicio_periodo ||= Date.today.beginning_of_month
  fim_periodo ||= Date.today
  
  with_db do |client|
    # Buscar todos os alunos ativos
    alunos = client.exec("SELECT id, nome FROM alunos ORDER BY nome").to_a
    
    # Buscar aulas no período
    aulas = client.exec_params(
      "SELECT id, data_aula FROM aulas WHERE data_aula BETWEEN $1 AND $2 ORDER BY data_aula",
      [inicio_periodo.to_s, fim_periodo.to_s]
    ).to_a
    
    # Para cada aluno, verificar a presença em cada aula
    resultados = []
    
    alunos.each do |aluno|
      presencas = 0
      faltas = 0
      
      aulas.each do |aula|
        presente = client.exec_params(
          "SELECT presente FROM presencas WHERE aluno_id = $1 AND aula_id = $2",
          [aluno['id'], aula['id']]
        ).first
        
        if presente && presente['presente'] == 't'
          presencas += 1
        else
          faltas += 1
        end
      end
      
      # Calcular a taxa de frequência
      taxa_frequencia = aulas.empty? ? 0 : (presencas.to_f / aulas.size * 100).round(2)
      
      resultados << {
        aluno_id: aluno['id'],
        nome: aluno['nome'],
        presencas: presencas,
        faltas: faltas,
        total_aulas: aulas.size,
        taxa_frequencia: taxa_frequencia
      }
    end

      resultados
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
    result = AulaService.criar_e_inicializar(params)
    result[:aula_id]
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
    AulaService.atualizar_presencas(aula_id, presentes)[:success]
  end
  def self.total_no_mes_atual
  inicio_mes = Date.today.beginning_of_month.to_s
  fim_mes = Date.today.end_of_month.to_s
  
  with_db do |client|
    client.exec_params(
      "SELECT COUNT(*) as total FROM aulas
       WHERE data_aula BETWEEN $1 AND $2",
      [inicio_mes, fim_mes]
    ).first['total'].to_i
    end
  end

  def self.total_no_mes_atual
  inicio_mes = Date.beginning_of_month(Date.today)
  fim_mes = Date.end_of_month(Date.today)
  
  with_db do |client|
    client.exec_params(
      "SELECT COUNT(*) as total FROM aulas
       WHERE data_aula BETWEEN $1 AND $2",
      [inicio_mes.to_s, fim_mes.to_s]
    ).first['total'].to_i
    end
  end
end

# Classe para gerenciar presenças
class Presenca
def self.total_no_mes_atual
  inicio_mes = Date.beginning_of_month(Date.today)
  fim_mes = Date.end_of_month(Date.today)
  
  with_db do |client|
    client.exec_params(
      "SELECT COUNT(*) as total FROM presencas p
       JOIN aulas a ON p.aula_id = a.id
       WHERE a.data_aula BETWEEN $1 AND $2 AND p.presente = TRUE",
      [inicio_mes.to_s, fim_mes.to_s]
    ).first['total'].to_i
    end
end

  def self.historico_ultimos_meses(quantidade = 6)
  with_db do |client|
    meses = []
    dados = []
    
    quantidade.downto(1) do |i|
      data = Date.today << i  # Recua i meses
      inicio_mes = Date.new(data.year, data.month, 1).to_s
      fim_mes = Date.new(data.year, data.month, -1).to_s
      
      resultado = client.exec_params(
        "SELECT COUNT(*) as total FROM presencas p
         JOIN aulas a ON p.aula_id = a.id
         WHERE a.data_aula BETWEEN $1 AND $2 AND p.presente = TRUE",
        [inicio_mes, fim_mes]
      ).first['total'].to_i
      
      meses.push("#{data.strftime('%b/%Y')}")
      dados.push(resultado)
    end
    
    {labels: meses, data: dados}
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
    def self.contar_por_status(status_texto)
    with_db do |client|
      count = 0
      assinaturas = client.exec("SELECT id FROM assinaturas WHERE status = 'ativa'").to_a
      
      assinaturas.each do |assinatura|
        status_info = verificar_status(assinatura['id'])
        count += 1 if status_info[:status] == status_texto
      end

      count
    end
  end
end
# Classe Notificacao
class Notificacao
  def self.todas
    with_db do |client|
      client.exec("SELECT * FROM notificacoes ORDER BY criado_em DESC").to_a
    end
  end
  
  def self.pendentes
    with_db do |client|
      client.exec("SELECT * FROM notificacoes WHERE lida = FALSE ORDER BY criado_em DESC").to_a
    end
  end
  
  def self.criar(titulo, mensagem, tipo = 'info')
    with_db do |client|
      client.exec_params(
        "INSERT INTO notificacoes(titulo, mensagem, tipo, lida, criado_em) 
         VALUES ($1, $2, $3, FALSE, NOW()) RETURNING id",
        [titulo, mensagem, tipo]
      ).first
    end
  end
  
  def self.marcar_como_lida(id)
    with_db do |client|
      client.exec_params(
        "UPDATE notificacoes SET lida = TRUE, lida_em = NOW() WHERE id = $1",
        [id]
      )
    end
  end
  
  def self.gerar_notificacoes_automaticas
    # Verificar mensalidades atrasadas
    with_db do |client|
      assinaturas = client.exec("SELECT a.id, al.nome FROM assinaturas a JOIN alunos al ON a.aluno_id = al.id WHERE a.status = 'ativa'").to_a
      
      assinaturas.each do |assinatura|
        status_info = Assinatura.verificar_status(assinatura['id'])
        
        if status_info[:status] == "Atrasado"
          titulo = "Mensalidade atrasada"
          mensagem = "A mensalidade do aluno #{assinatura['nome']} está atrasada."
          
          # Verificar se já existe notificação similar não lida
          notificacoes_existentes = client.exec_params(
            "SELECT id FROM notificacoes WHERE mensagem = $1 AND lida = FALSE",
            [mensagem]
          ).to_a
          
          if notificacoes_existentes.empty?
            criar(titulo, mensagem, 'warning')
          end
        end
      end
    end
    
    # Verificar aniversariantes do dia
    hoje = Date.today
    with_db do |client|
      aniversariantes = client.exec_params(
        "SELECT id, nome FROM alunos 
         WHERE EXTRACT(MONTH FROM data_nascimento) = $1 
         AND EXTRACT(DAY FROM data_nascimento) = $2",
        [hoje.month, hoje.day]
      ).to_a
      
      aniversariantes.each do |aluno|
        titulo = "Aniversário hoje!"
        mensagem = "Hoje é aniversário de #{aluno['nome']}."
        
        # Verificar se já existe notificação similar não lida
        notificacoes_existentes = client.exec_params(
          "SELECT id FROM notificacoes WHERE mensagem = $1 AND lida = FALSE",
          [mensagem]
        ).to_a
        
        if notificacoes_existentes.empty?
          criar(titulo, mensagem, 'info')
        end
      end
    end
  end
end
# ========================================
# HELPERS E MIDDLEWARES
# ========================================

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
  pagina = params[:pagina]&.to_i || 1
  por_pagina = params[:por_pagina]&.to_i || 20
  
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
  @turmas = TURMAS
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
    # Implementar no futuro
    status 404
    "Relatório de mensalidades em desenvolvimento"
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
  @turmas = TURMAS
  erb :editar_aluno
end

# Rota para o formulário de novo aluno
  get '/alunos/novo' do
    @faixas = FAIXAS
    @turmas = TURMAS
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
