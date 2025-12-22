require 'pg'
require 'connection_pool'

# Constante de tamanho do Pool
DB_POOL_SIZE = ENV.fetch('DB_POOL_SIZE', 10).to_i

# Pool de conexões para o banco de dados (otimizado)
DB_POOL = ConnectionPool.new(size: DB_POOL_SIZE, timeout: 5) do
  connection_params = if ENV['DATABASE_URL']
    ENV['DATABASE_URL']  # Usado pelo Render
  else
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
      # Usar STDERR diretamente em vez de tentar acessar settings.logger
      STDERR.puts "Erro de banco de dados: #{e.message}"
      raise
    end
  end
end