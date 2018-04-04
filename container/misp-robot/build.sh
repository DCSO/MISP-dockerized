#!/bin/bash
set -x
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Set default Value if no parameter is deployed:
[ -z $1 ] && FOLDER="1.0.0-ubuntu"
[ -z $1 ] || FOLDER="$1"

source $SCRIPTPATH/$FOLDER/configuration.sh

DOCKER_REPO="dcso/$CONTAINER_NAME"
DOCKERFILE_PATH=Dockerfile

sudo docker build --no-cache \
        --build-arg RELEASE_DATE="$(date +"%Y-%m-%d")" \
        --build-arg BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --build-arg NAME="$CONTAINER_NAME" \
        --build-arg GIT_REPO="$GIT_REPO" \
        --build-arg VCS_REF=$(git rev-parse --short HEAD) \
        --build-arg VERSION="$VERSION" \
    -f $SCRIPTPATH/$FOLDER/$DOCKERFILE_PATH -t $DOCKER_REPO:$FOLDER $SCRIPTPATH/$FOLDER/

# ##################################################
# # for documentation:
# ./generate-stackbrew-library.sh > $CONTAINER_NAME
# git clone git@github.com:8ear/official-images.git
# mv $CONTAINER_NAME official-images/library/