#!/bin/sh
#description     :This script remove all misp docker container, their volumes and the /opt/misp path.
#==============================================================================
set -eu

# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[DELETE]${NC}"

DELETE_CONTAINER="no"
DELETE_IMAGES="no"
DELETE_NETWORK="no"
DELETE_PRUNE="no"
DELETE_VOLUMES="no"

# Functions
echo (){
    command echo "$STARTMSG $*"
}


#
#   MAIN
#

# https://jonalmeida.com/posts/2013/05/26/different-ways-to-implement-flags-in-bash/
while [ ! $# -eq 0 ]
do
	case "$1" in
		"--help" | -h)
			usage
			exit
			;;
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
	shift
done

echo "This will remove MISP-dockerized container=$DELETE_CONTAINER, volumes=$DELETE_VOLUMES, network=$DELETE_NETWORK, images=$DELETE_IMAGES and dangling images=$DELETE_PRUNE? Are you sure? (y): "
[ "${CI-}" = "true" ] || read -r USER_GO

if [ "${CI-}" = "true" ];then
    USER_GO="y"
    DELETE_CONTAINER="yes"
    DELETE_NETWORK="yes"
    DELETE_PRUNE="yes"
    DELETE_VOLUMES="yes"
fi

if [ "$USER_GO" = "y" ]; then
    
    [ "$DELETE_CONTAINER" = "yes" ] && echo "Stop and remove all misp-dockerized container"
    # shellcheck disable=SC2046
    [ "$DELETE_CONTAINER" = "yes" ] && docker rm -f $(docker ps -aqf name=misp-*)
    
    [ "$DELETE_VOLUMES" = "yes" ] && echo "Remove all misp-dockerized volumes"
    # shellcheck disable=SC2046
    [ "$DELETE_VOLUMES" = "yes" ] && docker volume rm $(docker volume ls -qf name=misp-dockerized*)
    
    [ "$DELETE_IMAGES" = "yes" ] && echo "Remove all misp-dockerized images ###"
    # shellcheck disable=SC2046
    [ "$DELETE_IMAGES" = "yes" ] && docker image rm $(docker image ls --format '{{.Repository}}:{{.ID}}' | grep misp-dockerized | sed 's/^[^:]*://g')
    
    [ "$DELETE_PRUNE" = "yes" ] && echo "Remove all dangling"
    # shellcheck disable=SC2046
    [ "$DELETE_PRUNE" = "yes" ] && docker image rm $(docker image ls --filter "dangling=true" --quiet)

    [ "$DELETE_NETWORK" = "yes" ] && echo "Remove misp-dockerized Network"
    # shellcheck disable=SC2046
    [ "$DELETE_NETWORK" = "yes" ] && docker network rm $(docker network ls --format '{{.Name}}:{{.ID}}' | grep misp-backend | sed 's/^[^:]*://g')
fi
