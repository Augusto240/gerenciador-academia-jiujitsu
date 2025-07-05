#!/bin/sh
set -e

# Se DATABASE_HOST estiver definido, espera conexão antes de iniciar
if [ -n "$DATABASE_HOST" ]; then
  ./wait-for-it.sh "$DATABASE_HOST:3306" --timeout=60 --strict
fi

# Executa comando padrão
exec "$@"
