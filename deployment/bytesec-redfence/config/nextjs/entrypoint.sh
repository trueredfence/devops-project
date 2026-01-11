#!/bin/sh
set -e

echo "Entrypoint started..."

# Wait for DB to be ready
if [ -n "$DATABASE_URL" ]; then
  echo "Waiting for database to be ready..."
  until pg_isready -d "$DATABASE_URL" >/dev/null 2>&1; do
    sleep 2
  done
  echo "Database is ready!"
fi

# Run drizzle push if enabled
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "Running Drizzle push..."
  npx drizzle-kit push
fi

exec "$@"