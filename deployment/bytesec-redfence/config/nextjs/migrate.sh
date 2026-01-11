#!/bin/bash
set -e

echo "[INFO] Starting Redfence application..."
echo "[INFO] NODE_ENV: $NODE_ENV"
echo "[INFO] DATABASE_URL: ${DATABASE_URL%%:*}://***:***@${DATABASE_URL##*@}"

if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "[INFO] Running database migrations..."
    npx drizzle-kit migrate || {
        echo "[ERROR] Migration failed!"
        exit 1
    }
    echo "[INFO] Migrations completed successfully."
fi

echo "[INFO] Starting Next.js server..."
exec node server.js