#!/bin/sh
set -e

# Espera pela porta correta do PostgreSQL
if [ -n "$DATABASE_HOST" ]; then
  ./wait-for-it.sh "$DATABASE_HOST:5432" --timeout=60 --strict
fi

# Executa o comando principal passado pelo CMD do Dockerfile
exec "$@"