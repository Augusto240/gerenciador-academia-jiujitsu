require 'pg'
require 'connection_pool'

# Constante de tamanho do Pool
DB_POOL_SIZE = ENV.fetch('DB_POOL_SIZE', 10).to_i

# Pool de conexões para o banco de dados (otimizado)
DB_POOL = ConnectionPool.new(size: DB_POOL_SIZE, timeout: 5) do
  connection_params = if ENV['DATABASE_URL']
    ENV['DATABASE_URL']  # Usado pelo Render/Produção
  elsif ENV['RACK_ENV'] == 'production'
    # Em produção, exigir variáveis de ambiente
    raise "DATABASE_URL ou DATABASE_HOST/USER/PASSWORD não configurados!" unless ENV['DATABASE_HOST']
    {
      host: ENV.fetch('DATABASE_HOST'),
      user: ENV.fetch('DATABASE_USER'),
      password: ENV.fetch('DATABASE_PASSWORD'),
      dbname: ENV.fetch('DATABASE_NAME')
    }
  else
    # Em desenvolvimento, usar valores padrão do Docker
    {
      host: ENV.fetch('DATABASE_HOST', 'db'),
      user: ENV.fetch('DATABASE_USER', 'jiujitsu_user'),
      password: ENV.fetch('DATABASE_PASSWORD', 'senha_forte_123'),
      dbname: ENV.fetch('DATABASE_NAME', 'academia_jiujitsu_dev')
    }
  end
  
  PG.connect(connection_params)
end

# Helper global para usar o banco
def with_db
  DB_POOL.with do |conn|
    begin
      yield conn
    rescue PG::Error => e
      if ENV['RACK_ENV'] == 'production'
        STDERR.puts "Erro de banco de dados: [REDACTED]"
      else
        STDERR.puts "Erro de banco de dados: #{e.message}"
      end
      raise
    end
  end
end