#!/bin/bash
set -x
[ -z $1 ] && echo "please get Version as parameter." && exit 1
VERSION="$1"

CONTAINER_NAME="misp-server"

DOCKER_REPO="dcso/$CONTAINER_NAME"
IMAGE_NAME="$DOCKER_REPO:latest"
DOCKERFILE_PATH=Dockerfile

pushd $VERSION
source ./configuration.sh

sudo docker build \
        --build-arg BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --build-arg VCS_REF=$(git rev-parse --short HEAD) \
        --build-arg GIT_REPO="$GIT_REPO" \
        --build-arg MISP_TAG="$MISP_TAG" \
        --build-arg python_cybox_TAG="$python_cybox_TAG" \
        --build-arg python_stix_TAG="$python_stix_TAG" \
        --build-arg mixbox_TAG="$mixbox_TAG" \
        --build-arg cake_resque_TAG="$cake_resque_TAG" \
    -f $DOCKERFILE_PATH -t $IMAGE_NAME -t $DOCKER_REPO:$MISP_TAG .

popd

# ##################################################
# # for documentation:
# ./generate-stackbrew-library.sh > $CONTAINER_NAME
# git clone git@github.com:8ear/official-images.git
# mv $CONTAINER_NAME official-images/library/