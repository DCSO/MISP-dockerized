#!/bin/bash
set -xe


REPO="$1"
tag="$2"
image_id=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $REPO:$tag|cut -d : -f 3|head -n 1;)
image_tags=$(docker images --format "{{.Repository}}:{{.Tag}}:{{.ID}}"|grep $image_id|cut -d : -f 2;)
for i in $image_tags
do
    docker push misp-dockerized-$REPO:$i
done


echo "###########################################"
