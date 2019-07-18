#!/bin/sh
set -eu

STARTMSG="[tag]"

# first_version=5.100.2
# second_version=5.1.2
# if version_gt $first_version $second_version; then
#      echo "$first_version is greater than $second_version !"
# fi'
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

func_tag() {
    DOCKER_REPO="$1"
    TAG="$2"
    
    # add -dev 
    # shellcheck disable=SC2143
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
}

REGISTRY_URL="$1"

# Pull all latest tagged container
    echo
    echo "$STARTMSG Pull all latest-dev container..." && sleep 2
    docker pull "$REGISTRY_URL"/misp-dockerized-proxy:latest-dev;
	docker pull "$REGISTRY_URL"/misp-dockerized-robot:latest-dev;
	docker pull "$REGISTRY_URL"/misp-dockerized-server:latest-dev;
    docker pull "$REGISTRY_URL"/misp-dockerized-db:latest-dev;
    docker pull "$REGISTRY_URL"/misp-dockerized-redis:latest-dev;
    docker pull "$REGISTRY_URL"/misp-dockerized-monitoring:latest-dev;
    docker pull "$REGISTRY_URL"/misp-dockerized-misp-modules:latest-dev;


# prepare retagging
SERVER_TAG="$(docker ps -f name=server --format '{{.Image}}'|cut -d : -f 2)"
PROXY_TAG="$(docker ps -f name=proxy --format '{{.Image}}'|cut -d : -f 2)"
ROBOT_TAG="$(docker ps -f name=robot --format '{{.Image}}'|cut -d : -f 2)"
MODULES_TAG="$(docker ps -f name=modules --format '{{.Image}}'|cut -d : -f 2)"
DB_TAG=$(docker ps -f name=db --format '{{.Image}}'|cut -d : -f 2)
REDIS_TAG=$(docker ps -f name=redis --format '{{.Image}}'|cut -d : -f 2)
MONITORING_TAG=$(docker ps -f name=monitoring --format '{{.Image}}'|cut -d : -f 2)


  # retag all existing tags dev 2 public repo
    func_tag "$REGISTRY_URL/misp-dockerized-server" "$SERVER_TAG"
    func_tag "$REGISTRY_URL/misp-dockerized-proxy" "$PROXY_TAG"
    func_tag "$REGISTRY_URL/misp-dockerized-robot" "$ROBOT_TAG"
    func_tag "$REGISTRY_URL/misp-dockerized-misp-modules" "$MODULES_TAG"

    # For all container after 1.1.0
    if version_gt "$CURRENT_VERSION" "1.1.0" ; then
        func_tag "$REGISTRY_URL/misp-dockerized-redis" "$REDIS_TAG"
    fi

    # For all container after 1.2.0
    if version_gt "$CURRENT_VERSION" "1.1.0" ; then
        func_tag "$REGISTRY_URL/misp-dockerized-db" "$DB_TAG"
        func_tag "$REGISTRY_URL/misp-dockerized-monitoring" "$MONITORING_TAG"
    fi
    echo "###########################################" && docker images && echo "###########################################"

echo "$STARTMSG $0 is finished."
