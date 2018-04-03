# 
# Container Name
CONTAINER_NAME="misp-proxy"
# HTTPS GIT Repo URL:
GIT_REPO=https://github.com/DCSO/MISP-dockerized
# Version:
VERSION=1.0.0
# Automatic Docker Variable:
    DOCKER_REPO="dcso/$CONTAINER_NAME"
    IMAGE_NAME="$DOCKER_REPO:latest"
    DOCKERFILE_PATH=Dockerfile

# Tags
ADDITIONAL_TAGS=   "-t $DOCKER_REPO:alpine \
                    -t $DOCKER_REPO:$VERSION-alpine \
                    -t $DOCKER_REPO:$VERSION-latest"