#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# --- INÍCIO DA MIGRAÇÃO AUTOMÁTICA ---
echo "Inicializando banco de dados com a estrutura (schema)..."
psql $DATABASE_URL < initdb/10_schema.sql

# Verifica se o arquivo de dados de produção existe (como um Secret File)
if [ -f "initdb/30_production_data.sql" ]; then
  echo "Arquivo de dados de produção encontrado. Inserindo dados..."
  psql $DATABASE_URL < initdb/30_production_data.sql
else
  echo "Nenhum arquivo de dados de produção encontrado. Pulando a inserção de dados."
fi
# --- FIM DA MIGRAÇÃO AUTOMÁTICA ---

echo "Build finalizado com sucesso!"