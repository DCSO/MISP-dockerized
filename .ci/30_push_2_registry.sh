#!/bin/sh
STARTMSG="[push]"

func_push() {
    DOCKER_REPO="$1"
    tag="$2"

    echo "$STARTMSG ###################################################################"
    echo "$STARTMSG### remove dev MISP images after retagging ###";
    echo "$STARTMSG### remove: $1 with tag $2"
    [ -z $(docker image ls --format '{{.Repository}}:{{.Tag}}'|grep -e "$2-dev") ] || docker image rm -f $(docker image ls --format '{{.Repository}}:{{.Tag}}'|grep -e "$2-dev")
    [ -z $(docker image ls --format '{{.Repository}}:{{.Tag}}'|grep -e "$1:latest-dev") ] || docker image rm -f $(docker image ls --format '{{.Repository}}:{{.Tag}}'|grep -e "$1:latest-dev")
    docker images -f name=$DOCKER_REPO
    
    image_id=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $DOCKER_REPO:$tag|cut -d : -f 3|head -n 1;)
    image_tags=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $image_id|cut -d : -f 2;)
    for i in $image_tags
    do
        docker push $DOCKER_REPO:$i
    done
}

func_tag() {
    DOCKER_REPO="$1"
    tag="$2"
    set -xv 
    [ -z $(echo $tag| grep dev) ] && tag="$tag-dev"
    image_id=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $DOCKER_REPO:$tag|cut -d : -f 3|head -n 1;)
    image_tags=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $image_id|cut -d : -f 2;)
    for i in $image_tags
    do
        k=$(echo $i|sed 's,-dev$,,')
        docker tag $DOCKER_REPO:$i $DOCKER_REPO:$k; \
    done
}


# change directory for make usage
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
    make pull-latest REPOURL=${REGISTRY_URL}


# prepare retagging
SERVER_TAG=$(docker ps -f name=server --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
PROXY_TAG=$(docker ps -f name=proxy --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
ROBOT_TAG=$(docker ps -f name=robot --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
MODULES_TAG=$(docker ps -f name=modules --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
#DB_TAG=$(docker ps -f name=db --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)
#REDIS_TAG=$(docker ps -f name=redis --format '{{.Image}}'|cut -d : -f 2|cut -d - -f 3)


# Login to Docker registry
[ "$REGISTRY_URL" != "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" "$REGISTRY_URL" --password-stdin)"
[ "$REGISTRY_URL" == "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" --password-stdin)"
echo $DOCKER_LOGIN_OUTPUT
DOCKER_LOGIN_STATE="$(echo $DOCKER_LOGIN_OUTPUT | grep 'Login Succeeded')"

if [ ! -z "$DOCKER_LOGIN_STATE" ]; then
  # retag all existing tags dev 2 public repo
        #$makefile_travis tag REPOURL=$REGISTRY_URL server_tag=${server_tag} proxy_tag=${proxy_tag} robot_tag=${robot_tag} modules_tag=${modules_tag} db_tag=${modules_tag} redis_tag=${modules_tag} postfix_tag=${postfix_tag}
        func_tag $REGISTRY_URL/misp-dockerized-server $SERVER_TAG
        func_tag $REGISTRY_URL/misp-dockerized-proxy $PROXY_TAG
        func_tag $REGISTRY_URL/misp-dockerized-robot $ROBOT_TAG
        func_tag $REGISTRY_URL/misp-dockerized-misp-modules $MODULES_TAG
        echo "###########################################" && docker images && echo "###########################################"
    # Push all Docker images
        #$makefile_travis push REPOURL=$REGISTRY_URL server_tag=${server_tag} proxy_tag=${proxy_tag} robot_tag=${robot_tag} modules_tag=${modules_tag} postfix_tag=${postfix_tag} 
        func_push $REGISTRY_URL/misp-dockerized-server $SERVER_TAG
        func_push $REGISTRY_URL/misp-dockerized-proxy $PROXY_TAG
        func_push $REGISTRY_URL/misp-dockerized-robot $ROBOT_TAG
        func_push $REGISTRY_URL/misp-dockerized-misp-modules $MODULES_TAG
else
    echo $DOCKER_LOGIN_OUTPUT
    exit
fi

echo "$STARTMSG $0 is finished."
