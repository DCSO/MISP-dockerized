#!/bin/sh
STARTMSG="[push]"

[ -z "$1" ] && echo "$STARTMSG No parameter with the Docker registry URL. Exit now." && exit 1
[ "$1" == "NOT2PUSH" ] && echo "$STARTMSG The NOT2PUSH slug is only for local build and retag not for pushin to docker registries. Exit now." && exit 1
[ -z "$2" ] && echo "$STARTMSG No parameter with the Docker registry username. Exit now." && exit 1
[ -z "$3" ] && echo "$STARTMSG No parameter with the Docker registry password. Exit now." && exit 1

REGISTRY_URL="$1"
REGISTRY_USER="$2"
REGISTRY_PW="$3"


# Pull all latest tagged container
    echo
    echo "$START Pull all latest-dev container..."
    $makefile_travis pull-latest REPOURL=${REGISTRY_URL}


# prepare retagging
SERVER_TAG=$(docker ps -f name=server --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
PROXY_TAG=$(docker ps -f name=proxy --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
ROBOT_TAG=$(docker ps -f name=robot --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
modules_tag=$(docker ps -f name=modules --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
#DB_TAG=$(docker ps -f name=db --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
#REDIS_TAG=$(docker ps -f name=redis --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)


# Login to Docker registry
[ "$REGISTRY_URL" != "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" "$REGISTRY_URL" --password-stdin)"
[ "$REGISTRY_URL" == "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" --password-stdin)"
echo $DOCKER_LOGIN_OUTPUT
DOCKER_LOGIN_STATE="$(echo $DOCKER_LOGIN_OUTPUT | grep 'Login Succeeded')"

if [ ! -z "$DOCKER_LOGIN_STATE" ]; then
  # retag all existing tags dev 2 public repo
    $makefile_travis tag REPOURL=$REGISTRY_URL server_tag=${server_tag} proxy_tag=${proxy_tag} robot_tag=${robot_tag} modules_tag=${modules_tag} db_tag=${modules_tag} redis_tag=${modules_tag} postfix_tag=${postfix_tag}
  # Push all Docker images
    $makefile_travis push REPOURL=$REGISTRY_URL server_tag=${server_tag} proxy_tag=${proxy_tag} robot_tag=${robot_tag} modules_tag=${modules_tag} postfix_tag=${postfix_tag} 
else
    echo $DOCKER_LOGIN_OUTPUT
    exit
fi

echo "$STARTMSG $0 is finished."
