#/bin/bash

# check if user has currently a installed version
    # This function checks the current version on misp-server version from docker ps
    # https://forums.docker.com/t/docker-ps-a-command-to-publish-only-container-names/8483/2
    CURRENT_CONTAINER=$(docker ps --format '{{.Image}}'|grep server|cut -d : -f 2|cut -d - -f 1)
    [ "$CURRENT_CONTAINER" == "" ] && echo "Sorry, no Upgrade is possible. The reason is there is no running misp-server. I exit now." && docker ps && exit

# check if user has an installed version
[ ! -L ./current ] && echo "Sorry, no Update is possible. The reason is no 'current' directory exists. I exit now" && exit


###### UPDATE
pushd current
make install
popd