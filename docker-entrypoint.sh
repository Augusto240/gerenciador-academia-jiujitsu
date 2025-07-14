set -e

if [ -n "$DATABASE_HOST" ]; then
  ./wait-for-it.sh "$DATABASE_HOST:5432" --timeout=60 --strict
fi

exec "$@"