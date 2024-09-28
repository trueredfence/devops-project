# :star2: Docker-CheatSheet :star2:

A CheatSheet to get you started with docker 

## Installation 
```sh
 
  This is for Ubuntu
 
    - Install few packages which are required beforehand

    sudo apt install apt-transport-https ca-certificates curl software-properties-common

    - Add GPG key 

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    - Add Docker repository to apt sources

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

    - Update your existing list of packages
    
    sudo apt update

    - Install Docker-ce

    sudo apt install docker-ce

    - Start Docker Process

    sudo systemctl status docker 

```


## Docker commands :whale2:
```sh

 * Check all docker containers
   docker ps -a

 * Check all started docker containers
   docker ps

 * Start a stopped container
   docker start <container-name>

 * Stop a container
   docker stop <container-name>

 * Remove all containers
   docker stop $(docker ps -a -q)
   docker rm $(docker ps -a -q) 

 * Attach to a container
   docker start <container-name>
   docker attach <container-name>

 * Run bash shell in container
   docker container exec -it <container-name> bash
 
 * Delete container forcefully
   docker container rm -f <container-name>

 * Download a new docker image
   docker pull <image-name:version>

 * Docker Stats
   docker stats

 * See all Docker images
   docker images

 * Delete an Image
   docker rmi <image-name>
  
 * Remove all images
   docker image prune -a

 * Remove unused images
   docker image prune

 * Check all the networks created by docker
   docker network ls
 
 * Create Image from base container
   docker commit {base image} {new image name}

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

