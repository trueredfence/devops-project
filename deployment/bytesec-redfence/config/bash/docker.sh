#!/bin/bash

echo "[INFO] Cleaning up residual build layers..."
# Removes dangling images (safe)
docker image prune -f
# Removes build cache older than 24 hours (preserves speed, saves space)
docker builder prune --filter "until=24h" -f

docker system df