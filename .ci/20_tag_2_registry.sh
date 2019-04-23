#!/bin/sh
set -e 

STARTMSG="[tag]"


func_tag() {
    set -xv
    DOCKER_REPO="$1"
    TAG="$2"
    
    # add -dev 
    [ -z "$(echo "$TAG"| grep dev)" ] && TAG="$TAG-dev"
    IMAGE_ID="$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep "$DOCKER_REPO:$TAG"|cut -d : -f 3|head -n 1;)"
    IMAGE_TAGS="$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep "$IMAGE_ID"|cut -d : -f 2;)"
    for i in $IMAGE_TAGS
    do
        k="$(echo "$i"|sed 's,-dev$,,')"
        echo "$STARTMSG Retag: $DOCKER_REPO:$i with $DOCKER_REPO:$k"
        docker tag "$DOCKER_REPO:$i" "$DOCKER_REPO:$k"
        echo "$STARTMSG Remove: $DOCKER_REPO:$i"
        docker image rm "$DOCKER_REPO:$i"
    done
    set +xv
}


# change directory for make usage
[ -z "$1" ] && echo "$STARTMSG No parameter with the Docker registry URL. Exit now." && exit 1
[ "$1" = "NOT2PUSH" ] && echo "$STARTMSG The NOT2PUSH slug is only for local build and retag not for pushin to docker registries. Exit now." && exit 1
[ -z "$2" ] && echo "$STARTMSG No parameter with the Docker registry username. Exit now." && exit 1
[ -z "$3" ] && echo "$STARTMSG No parameter with the Docker registry password. Exit now." && exit 1

REGISTRY_URL="$1"
REGISTRY_USER="$2"
REGISTRY_PW="$3"


# Pull all latest tagged container
    echo
    echo "$STARTMSG Pull all latest-dev container..."
    make pull-latest REPOURL="$REGISTRY_URL"


# prepare retagging
SERVER_TAG="$(docker ps -f name=server --format '{{.Image}}'|cut -d : -f 2)"
PROXY_TAG="$(docker ps -f name=proxy --format '{{.Image}}'|cut -d : -f 2)"
ROBOT_TAG="$(docker ps -f name=robot --format '{{.Image}}'|cut -d : -f 2)"
MODULES_TAG="$(docker ps -f name=modules --format '{{.Image}}'|cut -d : -f 2)"
DB_TAG=$(docker ps -f name=db --format '{{.Image}}'|cut -d : -f 2)
REDIS_TAG=$(docker ps -f name=redis --format '{{.Image}}'|cut -d : -f 2)


# Login to Docker registry
[ "$REGISTRY_URL" != "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" "$REGISTRY_URL" --password-stdin)"
[ "$REGISTRY_URL" = "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" --password-stdin)"
echo "$DOCKER_LOGIN_OUTPUT"
DOCKER_LOGIN_STATE="$(echo "$DOCKER_LOGIN_OUTPUT" | grep 'Login Succeeded')"

if [ ! -z "$DOCKER_LOGIN_STATE" ]; then
  # retag all existing tags dev 2 public repo
        #$makefile_travis tag REPOURL=$REGISTRY_URL server_tag=${server_tag} proxy_tag=${proxy_tag} robot_tag=${robot_tag} modules_tag=${modules_tag} db_tag=${modules_tag} redis_tag=${modules_tag} postfix_tag=${postfix_tag}
        func_tag "$REGISTRY_URL/misp-dockerized-server" "$SERVER_TAG"
        func_tag "$REGISTRY_URL/misp-dockerized-server" "$SERVER_TAG"
        func_tag "$REGISTRY_URL/misp-dockerized-robot" "$ROBOT_TAG"
        func_tag "$REGISTRY_URL/misp-dockerized-misp-modules" "$MODULES_TAG"
        #func_tag "$REGISTRY_URL/misp-dockerized-db" "$DB_TAG"
        func_tag "$REGISTRY_URL/misp-dockerized-redis" "$REDIS_TAG"
        echo "###########################################" && docker images && echo "###########################################"
else
    echo "$DOCKER_LOGIN_OUTPUT"
    exit
fi

echo "$STARTMSG $0 is finished."
