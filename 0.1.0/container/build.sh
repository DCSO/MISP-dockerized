#!/bin/bash
#description     :This script build manually the docker container
#==============================================================================

# read the MISP tag from .env
MISP_TAG=$(cat .env |grep MISP_TAG|cut -d = -f 2)
MISP_TAG=${MISP_TAG#'"'}
MISP_TAG=${MISP_TAG%'"'}

# $2 for no-cache:
[ "$2" == "--no-cache" ] && CACHE="--no-cache"

pushd container

function mybuild(){
    CONTAINER="$1"
    echo -e "#\n#\tbuild $CONTAINER...\n#"
    docker build $CACHE -t dcso/$CONTAINER:$MISP_TAG -t dcso/$CONTAINER:latest $CONTAINER/
    [ -e "$CONTAINER/Dockerfile_alpine.yml" ] && echo -e "\n\n#\n#\tbuild $CONTAINER-alpine...\n#" && docker build $CACHE -t dcso/$CONTAINER:$MISP_TAG-alpine -t dcso/$CONTAINER:latest-alpine $CONTAINER/
}

case "$1" in
    server|all)
        mybuild misp-server
        ;;&
    robot|all)
        mybuild misp-robot
        ;;&
proxy|all)
        mybuild misp-proxy
        ;;
    *)
        echo -e "\n Sorry, '$1' was the false Input.\n Available Options:
                server
                proxy
                robot
                all
                "
esac
