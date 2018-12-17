#!/bin/bash
set -ex

echo "###################################################################"
echo "### remove dev MISP images after retagging ###";
echo "### remove: $1 with tag $2"
[ -z $(docker image ls --format '{{.Repository}}:{{.Tag}}'|grep -e "$2-dev") ] || docker image rm -f $(docker image ls --format '{{.Repository}}:{{.Tag}}'|grep -e "$2-dev")
[ -z $(docker image ls --format '{{.Repository}}:{{.Tag}}'|grep -e "$1:latest-dev") ] || docker image rm -f $(docker image ls --format '{{.Repository}}:{{.Tag}}'|grep -e "$1:latest-dev")
echo "###################################################################"
docker images
echo "###################################################################"
echo

DOCKER_REPO="$1"
tag="$2"
image_id=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $DOCKER_REPO:$tag|cut -d : -f 3|head -n 1;)
image_tags=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $image_id|cut -d : -f 2;)
for i in $image_tags
do
    echo "###################################################################"
    echo "# docker push $DOCKER_REPO:$i #"
    echo "###################################################################"
    docker push $DOCKER_REPO:$i
done

echo "###########################################"
