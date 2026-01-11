# Next.js Deployment & Docker Guide

This directory contains the deployment configuration for the Next.js application, including Nginx, Redis, and PostgreSQL setup.

## 🚀 Deployment Instructions

### Prerequisites
- Docker and Docker Compose installed on the host machine.
- Environment variables configured (see `docker-compose.yml` defaults).

### Quick Start
To build and start the entire stack in detached mode:

```bash
docker-compose up --build -d
```

Access the application at: `http://localhost` (or your configured domain).

---

## 🛠️ Docker Debugging & Management Cheat Sheet

### Service Management

**Start Services** (Detached mode)
```bash
docker-compose up -d
```

**Stop Services**
```bash
docker-compose down
```

**Build Services** (Force rebuild)
```bash
docker-compose up --build -d
```
*Useful when you've made changes to the `Dockerfile` or source code.*

### Logs & Monitoring

**View Logs (Follow Mode)**
```bash
docker-compose logs -f
```

**View Logs for Specific Service**
```bash
# Example: Only nextjs app logs
docker-compose logs -f redfence
# Example: Only nginx logs
docker-compose logs -f nginx
```

**Check Running Containers**
```bash
docker-compose ps
```

### Network & Storage

**Inspect Networks**
```bash
docker network ls
# Inspect specific network (e.g., deploy_frontend)
docker network inspect deploy_frontend
```

**Manage Volumes**
```bash
# List volumes
docker volume ls
# Inspect volume data location
docker volume inspect deploy_postgres_data
```

### Environment

**Check Runtime Environment Variables**
```bash
# Execute env command inside the running container
docker-compose exec redfence env
```

### Clean Up & Reset

**Stop and Remove Containers, Networks**
```bash
docker-compose down
```

**Deep Clean (Danger Zone)**
Stop containers and remove volumes (DELETES DATABASE DATA under `postgres_data`):
```bash
docker-compose down -v
```

**Purge Everything (System Prune)**
Remove unused data, stopped containers, and dangling images:
```bash
docker system prune -a --volumes
```

### Accessing Containers

**Shell into Next.js App**
```bash
docker-compose exec redfence sh

docker exec -it <container_name_or_id> /bin/bash
```

**Shell into Database**
```bash
docker-compose exec postgres psql -U postgres -d app
```
