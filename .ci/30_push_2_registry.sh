#!/bin/sh
set -e

STARTMSG="[push]"

# first_version=5.100.2
# second_version=5.1.2
# if version_gt $first_version $second_version; then
#      echo "$first_version is greater than $second_version !"
# fi'
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }


func_push() {
    DOCKER_REPO="$1"
    TAGS="$2"
    for i in $TAGS
    do
        [ ! -z "$(echo $i | grep 'dev')" ] && continue
        docker push "$DOCKER_REPO:$i"
    done
}

# change directory for make usage
[ -z "$1" ] && echo "$STARTMSG No parameter with the Docker registry URL. Exit now." && exit 1
[ "$1" = "NOT2PUSH" ] && echo "$STARTMSG The NOT2PUSH slug is only for local build and retag not for pushin to docker registries. Exit now." && exit 1
[ -z "$2" ] && echo "$STARTMSG No parameter with the Docker registry username. Exit now." && exit 1
[ -z "$3" ] && echo "$STARTMSG No parameter with the Docker registry password. Exit now." && exit 1

REGISTRY_URL="$1"
REGISTRY_USER="$2"
REGISTRY_PW="$3"

SERVER_TAGS="$(docker images --no-trunc --format '{{.Tag}}={{.ID}}' | grep $(docker inspect misp-server -f '{{.Image}}')|cut -d = -f 1)"
PROXY_TAGS="$(docker images --no-trunc --format '{{.Tag}}={{.ID}}' | grep $(docker inspect misp-proxy -f '{{.Image}}')|cut -d = -f 1)"
ROBOT_TAGS="$(docker images --no-trunc --format '{{.Tag}}={{.ID}}' | grep $(docker inspect misp-robot -f '{{.Image}}')|cut -d = -f 1)"
MODULES_TAGS="$(docker images --no-trunc --format '{{.Tag}}={{.ID}}' | grep $(docker inspect misp-modules -f '{{.Image}}')|cut -d = -f 1)"
#DB_TAGS=$(docker ps -f name=db --format '{{.Image}}'|cut -d : -f 2)
REDIS_TAGS="$(docker images --no-trunc --format '{{.Tag}}={{.ID}}' | grep $(docker inspect misp-redis -f '{{.Image}}')|cut -d = -f 1)"



# Login to Docker registry
[ "$REGISTRY_URL" != "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" "$REGISTRY_URL" --password-stdin)"
[ "$REGISTRY_URL" = "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" --password-stdin)"
echo "$DOCKER_LOGIN_OUTPUT"
DOCKER_LOGIN_STATE="$(echo "$DOCKER_LOGIN_OUTPUT" | grep 'Login Succeeded')"

if [ ! -z "$DOCKER_LOGIN_STATE" ]; then
#   # retag all existing tags dev 2 public repo
#         #$makefile_travis tag REPOURL=$REGISTRY_URL server_tag=${server_tag} proxy_tag=${proxy_tag} robot_tag=${robot_tag} modules_tag=${modules_tag} db_tag=${modules_tag} redis_tag=${modules_tag} postfix_tag=${postfix_tag}
#         func_tag "$REGISTRY_URL/misp-dockerized-server" "$SERVER_TAG"
#         func_tag "$REGISTRY_URL/misp-dockerized-server" "$SERVER_TAG"
#         func_tag "$REGISTRY_URL/misp-dockerized-robot" "$ROBOT_TAG"
#         func_tag "$REGISTRY_URL/misp-dockerized-misp-modules" "$MODULES_TAG"
#         #func_tag "$REGISTRY_URL/misp-dockerized-db" "$DB_TAG"
#         func_tag "$REGISTRY_URL/misp-dockerized-redis" "$REDIS_TAG"
#         echo "###########################################" && docker images && echo "###########################################"
    # Push all Docker images
        #$makefile_travis push REPOURL=$REGISTRY_URL server_tag=${server_tag} proxy_tag=${proxy_tag} robot_tag=${robot_tag} modules_tag=${modules_tag} postfix_tag=${postfix_tag} 
        func_push "$REGISTRY_URL/misp-dockerized-server" "$SERVER_TAGS"
        func_push "$REGISTRY_URL/misp-dockerized-proxy" "$PROXY_TAGS"
        func_push "$REGISTRY_URL/misp-dockerized-robot" "$ROBOT_TAGS"
        func_push "$REGISTRY_URL/misp-dockerized-misp-modules" "$MODULES_TAGS"
        if version_gt "$CURRENT_VERSION" "1.1.0" ; then
            func_push "$REGISTRY_URL/misp-dockerized-redis" "$REDIS_TAGS"
        fi
        #func_push "$REGISTRY_URL/misp-dockerized-db" "$DB_TAGS"
else
    echo "$DOCKER_LOGIN_OUTPUT"
    exit
fi

echo "$STARTMSG $0 is finished."
