#!/bin/sh
set -e
STARTMSG="[before_install]"

# Install Requirements
echo
echo "$STARTMSG Install requirements..."
    [ ! -z "$(which apk)" ] && apk add --no-cache bash sudo git curl coreutils grep py-pip python-dev libffi-dev openssl-dev gcc libc-dev make
    [ ! -z "$(which apt-get)" ] && apt-get update; 
    [ ! -z "$(which apt-get)" ] && apt-get install make bash sudo git curl coreutils grep python3 gcc
    # Upgrade Docke
    [ ! -z "$(which apt-get)" ] && apt-get install --only-upgrade docker-ce -y
# Install docker-compose
    # https://stackoverflow.com/questions/42295457/using-docker-compose-in-a-gitlab-ci-pipeline
    [ -z "$(which docker-compose)" ] && pip install docker-compose
# Show version of docker-compose:
    docker-compose -v

# Set Git Options
    echo
    echo "$STARTMSG Set Git options..."
    git config --global user.name "MISP-dockerized-bot"

echo "$STARTMSG $0 is finished."
