#!/bin/sh

# Travis CI Env Vars: https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
# Gitlab CI Env Vars: https://docs.gitlab.com/ee/ci/variables/

export FOLDER="./current"
export ENV_OPTION="$FOLDER/"
export MAKE_OPTION="-C $FOLDER"
export makefile_main="make -C $FOLDER"
export DOCKER_COMPOSE_OPTION="-f $FOLDER/docker-compose"
export makefile_travis="make -C $FOLDER/.travis"
export DEV=true