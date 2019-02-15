#!/bin/sh
STARTMSG="[before_install]"

# Install Requirements
echo
echo "$STARTMSG Install requirements..."
    [ ! -z "$(which apk)" ] && apk add --no-cache make bash sudo git curl coreutils grep python3
    [ ! -z "$(which apt-get)" ] && apt-get update; 
    [ ! -z "$(which apt-get)" ] && apt-get install make bash sudo git curl coreutils grep python3
    # Upgrade Docke
    [ ! -z "$(which apt-get)" ] && apt-get install --only-upgrade docker-ce -y
# Install docker-compose
    # https://stackoverflow.com/questions/42295457/using-docker-compose-in-a-gitlab-ci-pipeline
    [ -z "$(which docker-compose)" ] && pip3 install --no-cache-dir docker-compose
# Show version of docker-compose:
    docker-compose -v

# Set Git Options
    echo
    echo "$STARTMSG Set Git options..."
    git config --global user.name "MISP-dockerized-bot"

echo "$STARTMSG $0 is finished."
