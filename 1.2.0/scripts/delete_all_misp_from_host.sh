#!/bin/bash
#description     :This script remove all misp docker container, their volumes and the /opt/misp path.
#==============================================================================
STARTMSG="[DELETE]"
#set -

DELETE_CONTAINER="no"
DELETE_IMAGES="no"
DELETE_NETWORK="no"
DELETE_NETWORK="no"
DELETE_PRUNE="no"
DELETE_VOLUMES="no"

for i in $*
    do
        case "$i" in 
            "--network")
                DELETE_NETWORK="yes"
                ;;
            "--volumes")
                DELETE_VOLUMES="yes"
                ;;
            "--container")
                DELETE_CONTAINER="yes"
                ;;
            "--images")
                DELETE_IMAGES="yes"
                ;;
            "--prune")
                DELETE_PRUNE="yes"
                ;;
            *)
            echo "$STARTMSG False Parameter."
        esac
    done


echo "$STARTMSG This will remove container=$DELETE_CONTAINER, volumes=$DELETE_VOLUMES, network=$DELETE_NETWORK, images=$DELETE_IMAGES and dangling images=$DELETE_PRUNE ."
[ CI == "true" ] || read -p "Are you sure? (y): " USER_GO
[ CI == "true" ] && USER_GO="y"
if [ "$USER_GO" == "y" ]; then
    
    [ "$DELETE_CONTAINER" = "yes" ] && echo "$STARTMSG Stop and remove all misp-dockerized container"
    [ "$DELETE_CONTAINER" = "yes" ] && docker rm -f $(docker ps -aqf name=misp-*)
    
    [ "$DELETE_VOLUMES" = "yes" ] && echo "$STARTMSG Remove all misp-dockerized volumes"
    [ "$DELETE_VOLUMES" = "yes" ] && docker volume rm $(docker volume ls -qf name=misp-dockerized*)
    
    [ "$DELETE_IMAGES" = "yes" ] && echo "$STARTMSG Remove all misp-dockerized images ###"
    [ "$DELETE_IMAGES" = "yes" ] && docker image rm $(docker image ls --format '{{.Repository}}:{{.ID}}' | grep misp-dockerized | sed 's/^[^:]*://g')
    
    [ "$DELETE_PRUNE" = "yes" ] && echo "$STARTMSG Remove all dangling"
    [ "$DELETE_PRUNE" = "yes" ] && docker image rm $(docker image ls --filter "dangling=true" --quiet)

    [ "$DELETE_NETWORK" = "yes" ] && echo "$STARTMSG Remove misp-dockerized Network"
    [ "$DELETE_NETWORK" = "yes" ] && docker network rm $(docker network ls --format '{{.Name}}:{{.ID}}' | grep misp-dockerized | sed 's/^[^:]*://g')
fi
