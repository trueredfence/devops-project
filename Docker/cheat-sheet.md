# Docker Cheat Sheet

This cheat sheet provides common Docker commands for quick reference to manage containers, images, networks, and volumes.

## Table of Contents

- [Basic Commands](#basic-commands)
- [Image Management](#image-management)
- [Container Interaction](#container-interaction)
- [Docker Compose](#docker-compose)
- [Docker System Management](#docker-system-management)
- [Docker Network Management](#docker-network-management)
- [Docker Volume Management](#docker-volume-management)

## Basic Commands

- **Check Docker Version**

  ```bash
  docker --version
  ```

- **Run a Container**

  ```bash
  docker run -d -p <host_port>:<container_port> --name <container_name> <image_name>
  ```

- **List Running Containers**

  ```bash
  docker ps
  ```

- **List All Containers**

  ```bash
  docker ps -a
  ```

- **Stop a Running Container**

  ```bash
  docker stop <container_id>
  ```

- **Remove a Container**

  ```bash
  docker rm <container_id>
  ```

- **Remove All Stopped Containers**
  ```bash
  docker container prune
  ```
- **All container in docker**
  ```bash
  docker rm $(sudo docker ps -a -q)
  ```

## Image Management

- **List All Images**

  ```bash
  docker images
  ```

- **Remove an Image**

  ```bash
  docker rmi <image_id>
  ```

- **Pull an Image from Docker Hub**

  ```bash
  docker pull <image_name>
  ```

- **Build an Image from a Dockerfile**
  ```bash
  docker build -t <image_name> .
  ```
- **All images in docker**
  ```bash
  docker rmi $(sudo docker images -q)
  ```

## Container Interaction

- **Access a Running Container’s Shell**

  ```bash
  docker exec -it <container_id> /bin/bash
  ```

- **View Logs of a Container**

  ```bash
  docker logs <container_id>
  ```

- **Follow Logs Continuously**
  ```bash
  docker logs -f <container_id>
  ```

## Docker Compose

- **Start Containers Defined in a `docker-compose.yml`**

  ```bash
  docker-compose up -d
  ```

- **Stop Containers Started by Compose**
  ```bash
  docker-compose down
  ```

## Docker System Management

- **View System-Wide Docker Information**

  ```bash
  docker info
  ```

- **Clean Up Unused Data (Images, Containers, Volumes)**
  ```bash
  docker system prune
  ```

## Docker Network Management

- **List Networks**

  ```bash
  docker network ls
  ```

- **Create a Network**

  ```bash
  docker network create <network_name>
  ```

- **Inspect a Network**

  ```bash
  docker network inspect <network_name>
  ```

- **Connect a Container to a Network**

  ```bash
  docker network connect <network_name> <container_name>
  ```

- **Disconnect a Container from a Network**
  ```bash
  docker network disconnect <network_name> <container_name>
  ```

## Docker Volume Management

- **List Volumes**

  ```bash
  docker volume ls
  ```

- **Create a Volume**

  ```bash
  docker volume create <volume_name>
  ```

- **Inspect a Volume**

  ```bash
  docker volume inspect <volume_name>
  ```

- **Remove a Volume**

  ```bash
  docker volume rm <volume_name>
  ```

- **Remove All Unused Volumes**
  ```bash
  docker volume prune
  ```

## Launching containers :computer:

```sh

 * Launch container from an image
   docker run -itd --name <container-name>  <image-name>

   i: interactive
   t: tty
   d: background process

 * Launch container with specific port
   docker run -it -p <host-port>:<docker-port>  <image-name>

 * Lauching an nginx container which runs on port 80
   docker pull nginx
   docker run -itd -p 80:80  --name webserver  nginx

   Check using docker ps container should be present

 * Check a running container
   docker inspect <container-name>

```

## Docker file :package:

```sh

 * Build a docker image using a Dockerfile
   docker build -t <image name you want to give>  <Dockerfile path>


 * Push image to docker hub
   docker login  (Login to docker hub only needed once)
   docker tag <localsystem image name>   <username>/<preferred image name>
   docker push <username>/<preferred image name>


```

## Install docker compose

```sh

 - Download the latest version of Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

 - Change file permissions
   sudo chmod +x /usr/local/bin/docker-compose

 - Linking
   sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

 - Verify Installation
   docker–compose –version

```

## Working with docker compose

```sh

 - Launch containers using docker compose file
   docker-compose up

 - Launch in background
   docker-compose up -d

 - Check logs of docker compose
   docker-compose logs

```
