#!/bin/bash
#description     :This script remove all misp docker container, their volumes and the /opt/misp path.
#==============================================================================

echo "This will remove all container, volumes and corresponding images."
[ CI == "true" ] || read -p "Are you sure? (y): " USER_GO
[ CI == "true" ] && USER_GO="y"
if [ "$USER_GO" == "y" ]; then
    echo '### stop and remove all container ###'
    docker rm -f $(docker ps -aqf name=misp*)
    echo '### remove all volumes ###'
    docker volume rm $(docker volume ls -qf name=misp*)
    echo '### remove MISP images ###'
    #docker image rm $(docker image ls --format '{{.Repository}}:{{.ID}}' | grep misp | sed 's/^[^:]*://g')
    echo '### remove MISP Network'
    docker network rm $(docker network ls --format '{{.Name}}:{{.ID}}' | grep misp | sed 's/^[^:]*://g')
fi
