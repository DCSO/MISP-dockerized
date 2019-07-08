#!/bin/sh
set -e
STARTMSG="[before_install]"

# Install Requirements
echo
echo "$STARTMSG Install requirements..."
    
    
    # Gitlab Alpine Image:
    if [ "$GITLAB_CI" = "true" ]; then
    ### INTEGRATED in gitlab.dcso.lolcat:4567/misp/helper-containers:docker_compose
    # [ ! -z "$(command -v apk)" ] && apk add --no-cache \
    #     bash \
    #     # sudo \
    #     git  \
    #     # curl \
    #     # coreutils 
    #     make
        echo ""
    # Travis CI - Ubuntu Based:
    elif [ "${TRAVIS_CI-}" = "true" ];then
        [ ! -z "$(command -v apt-get)" ] && apt-get update; 
        # Upgrade Docker
        [ ! -z "$(command -v apt-get)" ] && apt-get install --only-upgrade docker-ce -y
    # Local Development PC:
    elif [ -n "${TRAVIS_CI-}" ];then
        [ ! -z "$(command -v apt-get)" ] && apt-get install \
            make \
            bash \
            sudo \
            git  \
            curl \
            # coreutils \
            grep
        # Install docker-compose
        # https://stackoverflow.com/questions/42295457/using-docker-compose-in-a-gitlab-ci-pipeline
        [ -z "$(command -v docker-compose)" ] && pip install docker-compose
    fi

# Show version of docker-compose:
    docker-compose -v

# Set Git Options
    echo
    echo "$STARTMSG Set Git options..."
    git config --global user.name "MISP-dockerized-bot"

echo "$STARTMSG $0 is finished."
