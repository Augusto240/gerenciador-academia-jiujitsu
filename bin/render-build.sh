#!/usr/bin/env bash
# exit on error
set -o errexit

# Instalar dependências
bundle install

# Criar diretório de logs
mkdir -p logs

# Criar tabelas no banco de dados
echo "Inicializando banco de dados com esquema..."
cat ./initdb/10_schema.sql | bundle exec ruby -e "require 'pg'; conn = PG.connect(ENV['DATABASE_URL']); puts conn.exec(STDIN.read).inspect"

echo "Banco de dados inicializado com sucesso!"