## Configuration

1. If mysql server/docker image already running on different group with different network first we have to to identify the network and secound we have to identify the name of docker container of mysql server.

   ```bash
   docker network ls
   docker ps | grep mysql
   docker-compose up -d
   docker-compose up --build -d
   ```

```bash
npm install express --save --no-fund --no-audit
npm install express --save --dry-run
npm install express --package-lock-only

```

2. Edit your docker compose file as per network and container name.
