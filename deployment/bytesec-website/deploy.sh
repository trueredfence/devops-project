#!/bin/bash
set -e

BRANCH=$1
SERVICE_NAME=""

if [ "$BRANCH" == "main" ]; then
    SERVICE_NAME="bytesec-prod"
elif [ "$BRANCH" == "uat" ]; then
    SERVICE_NAME="bytesec-uat"
else
    echo "Invalid branch. Use 'main' or 'uat'."
    exit 1
fi

echo "[INFO] Starting deployment for: $SERVICE_NAME"

# Build and restart only the changed service
docker compose build $SERVICE_NAME
docker compose up -d $SERVICE_NAME

# Refresh Nginx to ensure it sees the updated container
docker exec nginx-gateway nginx -s reload

# Cleanup to save disk (important for cheap startup VMs)
docker image prune -f

echo "[SUCCESS] $SERVICE_NAME is updated and running."