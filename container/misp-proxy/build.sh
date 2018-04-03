#!/bin/bash
set -x

# check if at least one parameter exists
[ -z $1 ] && echo "please get Version as parameter." && exit 1
FOLDER="$1"

source $FOLDER/configuration.sh

DOCKER_REPO="dcso/$CONTAINER_NAME"
IMAGE_NAME="$DOCKER_REPO:latest"
DOCKERFILE_PATH=Dockerfile

sudo docker build \
        --build-arg RELEASE_DATE="$(date +"%Y-%m-%d")" \
        --build-arg BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --build-arg NAME="$CONTAINER_NAME" \
        --build-arg GIT_REPO="$GIT_REPO" \
        --build-arg VCS_REF=$(git rev-parse --short HEAD) \
        --build-arg VERSION="$VERSION" \
    -f $FOLDER/$DOCKERFILE_PATH -t $IMAGE_NAME -t $DOCKER_REPO:$FOLDER $FOLDER/

# ##################################################
# # for documentation:
# ./generate-stackbrew-library.sh > $CONTAINER_NAME
# git clone git@github.com:8ear/official-images.git
# mv $CONTAINER_NAME official-images/library/