#!/usr/bin/env bash

# Careful! This script will destroy all containers and images!

docker kill $(docker ps -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
docker system prune -af --volumes
docker builder prune -af

#echo -n -e '\e[2J\e[3J\e[1;1H'
#clear
