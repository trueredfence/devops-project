#!/bin/bash

# -----------------------------------------------------------------------------
# Redfence Deployment Script
# Description: Professional deployment orchestration for Next.js 16+
# Architecture: Project Root Execution
# -----------------------------------------------------------------------------

set -e

# 1. Environment Setup
# Resolve the project root based on the script's physical location
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

# Define local configuration files
ENV_FILE=".env"
COMPOSE_FILE="compose.yaml"

echo "----------------------------------------------"
echo " Redfence Deployment Initiation"
echo "----------------------------------------------"
echo "[INFO] Working Directory: $PROJECT_ROOT"

# Verify required configuration files exist in the root
if [ ! -f "$ENV_FILE" ]; then 
    echo "[ERROR] Environment file (.env) not found in project root."
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then 
    echo "[ERROR] Compose file (compose.yaml) not found in project root."
    exit 1
fi

# 2. Build Process
# Build images using the local context and specified Dockerfile targets
echo "[INFO] Commencing image build for application and migration services..."
docker compose build --no-cache

# 3. Database Migration Gate
# Execute migrations as a standalone task before application startup
echo "[INFO] Executing database migrations..."
# Note: 'run --rm' creates a temporary container to execute migrations
docker compose run --rm migrate

# Capture the exit code of the migration process
if [ $? -ne 0 ]; then
    echo "[ERROR] Database migration failed. Aborting deployment for system stability."
    exit 1
fi

echo "[INFO] Database migration completed successfully."

# 4. Service Deployment
# Update containers with zero-downtime strategy (up -d)
# Docker Compose automatically detects changes and replaces containers
echo "[INFO] Updating application services..."
docker compose up -d --remove-orphans

# 5. Health Verification
# Monitoring the 'redfence' service health status as defined in compose.yaml
echo -n "[INFO] Validating service health..."
MAX_RETRIES=20
COUNT=0
HEALTH_STATUS="starting"

while [ $COUNT -lt $MAX_RETRIES ]; do
    HEALTH_STATUS=$(docker inspect -f '{{.State.Health.Status}}' redfence 2>/dev/null || echo "not_found")
    if [ "$HEALTH_STATUS" == "healthy" ]; then
        echo -e "\n[INFO] Service health check passed."
        break
    fi
    echo -n "."
    sleep 5
    ((COUNT++))
done

if [ "$HEALTH_STATUS" != "healthy" ]; then
    echo -e "\n[ERROR] Service failed health check within the allocated timeout."
    echo "[INFO] Displaying recent logs for diagnostics:"
    docker compose logs --tail=30 redfence
    exit 1
fi

# 6. Proxy Configuration Refresh
# Reload Nginx configuration without stopping the container
echo "[INFO] Refreshing Nginx configuration..."
docker compose exec -T nginx nginx -s reload || echo "[WARN] Nginx reload signal failed."

# 7. System Optimization
# Remove temporary build layers and dangling images to conserve disk space
echo "[INFO] Performing post-deployment cleanup..."
docker image prune -f

echo "----------------------------------------------"
echo " Deployment Operation Successful"
echo "----------------------------------------------"