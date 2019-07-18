#!/bin/sh
set -eu

STARTMSG="[02_script]"

# change directory for make usage
cd ..

[ -z "$1" ] && echo "$STARTMSG No parameter with the Docker registry URL. Exit now." && exit 1
[ "$1" = "NOT2PUSH" ] && echo "$STARTMSG The NOT2PUSH slug is only for local build and retag not for pushin to docker registries. Exit now." && exit 1
[ -z "$2" ] && echo "$STARTMSG No parameter with the Docker registry username. Exit now." && exit 1
[ -z "$3" ] && echo "$STARTMSG No parameter with the Docker registry password. Exit now." && exit 1
[ -z "$4" ] && echo "$STARTMSG No parameter with the test type [ long_test | no_test ]. Exit now." && exit 1
[ -z "$5" ] && echo "$STARTMSG No parameter with the current version. Exit now." && exit 1

REGISTRY_URL="$1"
#REGISTRY_USER="$2"
#REGISTRY_PW="$3"
TEST_TYPE="$4"
CURRENT_VERSION="$5"
#DOCKER_LOGIN_OUTPUT=""


### INTEGRATED in gitlab.dcso.lolcat:4567/misp/helper-containers:docker_compose
# Login to Docker registry
# echo "$STARTMSG Try to login to Docker registry... (Only with Gitlab CI)"
# [ "${GITLAB_CI-}" = "true" ] && [ "$REGISTRY_URL" != "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" "$REGISTRY_URL" --password-stdin)"
# [ "${GITLAB_CI-}" = "true" ] && [ "$REGISTRY_URL" = "dcso" ] && DOCKER_LOGIN_OUTPUT="$(echo "$REGISTRY_PW" | docker login -u "$REGISTRY_USER" --password-stdin)"
# echo "$DOCKER_LOGIN_OUTPUT"

###### Create current folder 
# Choose the Environment Version
    echo
    echo "$STARTMSG Create current folder and choose version..."
    bash ./FOR_NEW_INSTALL.sh "$CURRENT_VERSION"
    ls -la config/


# Build config and deploy environent
    # shellcheck disable=SC2154
    echo "$STARTMSG Build Configuration..." && $makefile_main build-config
    echo "$STARTMSG Pull Images..." && docker-compose -f current/docker-compose.yml -f current/docker-compose.override.yml pull -q
    [ ! -d reports ] && mkdir reports
    echo "$STARTMSG Start Environment..." && docker-compose -f current/docker-compose.yml -f current/docker-compose.override.yml up --abort-on-container-exit > reports/docker-compose-output.txt &
    ###########################################################
    #       ATTENTION   ATTENTION   ATTENTION
    #   If you want to use docker-in-docker (dind) you cant start docker container on another filesystem!!!! You need to do it from the docker-compose directly!!!
    #   Source: https://stackoverflow.com/questions/31381322/docker-in-docker-cannot-mount-volume
    ############################################################

# Wait a short time
    sleep 10
# show docker container
     echo "$STARTMSG show running docker container..." &&  docker ps

# Automated test
if [ "$TEST_TYPE" = "long_test" ]
then 
    echo "$STARTMSG test environment..." &&  make -C .ci test; 
    # Wait a short time
        sleep 10
    # show docker container
        echo "$STARTMSG show running docker container..." &&  docker ps
fi  

$makefile_main configure
# show config folders
    ls -laR config/

