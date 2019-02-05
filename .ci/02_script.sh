#!/bin/sh
STARTMSG="[build-script]"

TEST_TYPE="$1"

###### Create current folder 
# Choose the Environment Version
    echo
    echo "$STARTMSG Create current folder and choose version..."
    bash ./FOR_NEW_INSTALL.sh $CURRENT_VERSION


# Build config and deploy environent
    echo "$STARTMSG build configuration..." && $makefile_main build-config
     echo "$STARTMSG pull images..." && docker-compose -f current/docker-compose.yml -f current/docker-compose.override.yml pull
     echo "$STARTMSG start environment..." && docker-compose -f current/docker-compose.yml -f current/docker-compose.override.yml up -d
    ###########################################################
    #       ATTENTION   ATTENTION   ATTENTION
    #   If you want to use docker-in-docker (dind) you cant start docker container on another filesystem!!!! You need to do it from the docker-compose directly!!!
    #   Source: https://stackoverflow.com/questions/31381322/docker-in-docker-cannot-mount-volume
    ############################################################

# Wait a short time
    sleep 10
# show docker container
     echo "$STARTMSG show running docker container..." &&  docker ps

# Automated test
if [[ "$TEST_TYPE" == "long_test" ]]; then echo "$STARTMSG test environment..." &&  $makefile_travis test; fi  

# show config folders
    ls -laR config/

# Clean Up
echo "$STARTMSG clean up..." &&  make -C $FOLDER delete
