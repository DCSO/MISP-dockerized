#!/bin/bash
#description     :This script install and start the official docker security container.
#==============================================================================

if [ -d docker-bench-security ]
    then
        pushd docker-bench-security
        git pull
    else
        git clone https://github.com/docker/docker-bench-security.git
        pushd docker-bench-security
fi
docker-compose run --rm docker-bench-security
