#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# --- INÍCIO DA MIGRAÇÃO AUTOMÁTICA ---
echo "Inicializando banco de dados com a estrutura (schema)..."
psql $DATABASE_URL < initdb/10_schema.sql

# Define o caminho para o arquivo de dados de produção
PROD_DATA_FILE="/etc/secrets/production_data.sql"

# Verifica se o arquivo de dados de produção existe (como um Secret File)
if [ -f "$PROD_DATA_FILE" ]; then
  echo "Arquivo de dados de produção encontrado. Inserindo dados..."
  psql $DATABASE_URL < "$PROD_DATA_FILE"
else
  echo "Nenhum arquivo de dados de produção encontrado. Pulando a inserção de dados."
fi
# --- FIM DA MIGRAÇÃO AUTOMÁTICA ---

echo "Build finalizado com sucesso!"