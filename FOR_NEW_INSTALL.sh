#!/bin/bash
set -eu

param_VERSION=${1:-""}

while (( $(( $# - 1 )) )) && [ $# -ge 2 ]; do
    case "$(echo "${2-}"|cut -d = -f 1)" in
      server)
        SERVER_TAG="$(echo "${2-}"|cut -d = -f 2)"
      ;;
      redis)
        REDIS_TAG="$(echo "${2-}"|cut -d = -f 2)"
      ;;      
      proxy)
        PROXY_TAG="$(echo "${2-}"|cut -d = -f 2)"
      ;;
      db)
        DB_TAG="$(echo "${2-}"|cut -d = -f 2)"
      ;;
      modules)
        MODULES_TAG="$(echo "${2-}"|cut -d = -f 2)"
      ;;
      monitoring)
        MONITORING_TAG="$(echo "${2-}"|cut -d = -f 2)"
      ;;
      robot)
        ROBOT_TAG="$(echo "${2-}"|cut -d = -f 1)"
      ;;
      * )
        echo "Not defined container!"
        echo "Please use '$0 [VERSION] [COMPONENT]=[NEW_TAG]'"
        echo "Components: server | redis | proxy | db | modules | montitoring | robot"
        echo "Example: '$0 1.2.0 server=2.4.nightly-debian'"
        echo "Exit now."
        exit 1
      ;;
    esac
    shift
  done


# full path <version>/scripts	
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Create an array with all folder
    FOLDER=( */)
    FOLDER=( "${FOLDER[@]%/}" )

# set current version to ""
CURRENT_VERSION="$param_VERSION"

# check if user has currently a installed version
    function check_version_legacy (){
        # This function checks the current version on misp-server version from docker ps
        # https://forums.docker.com/t/docker-ps-a-command-to-publish-only-container-names/8483/2
        #CURRENT_CONTAINER=$(docker ps --format '{{.Image}}'|grep misp-dockerized-server|cut -d : -f 2|cut -d - -f 1)
        CURRENT_CONTAINER="$(docker exec misp-server printenv|grep VERSION|cut -d = -f 2)"
        [ "$CURRENT_CONTAINER" = "2.4.99" ] && CURRENT_VERSION="1.0.3" && return
        [ "$CURRENT_CONTAINER" = "2.4.94" ] && CURRENT_VERSION="0.3.4" && return
        [ "$CURRENT_CONTAINER" = "2.4.92" ] && CURRENT_VERSION="0.2.0" && return
        [ "$CURRENT_CONTAINER" = "2.4.88" ] && CURRENT_VERSION="0.1.2" && return
        echo "Sorry you use a unsupported version. Please make an manual upgrade."
    }
    
    function check_version(){
        # This function checks the current link to which version it goes
        # https://www.linuxquestions.org/questions/linux-software-2/how-to-find-symlink-target-name-in-script-364971/
        CURRENT_VERSION="$(ls -l current | awk '{print $11}')"
    }

    # if current symlink exists
    [ -L ./current ] && [ -z "$CURRENT_VERSION" ] && check_version
    # if current symlink not exists
    [ -L ./current ] && [ -z "$CURRENT_VERSION" ] && check_version_legacy


############### START MAIN ###################


# check if this execution is automatic from gitlab-ci or travis-ci
    if [ "${CI-}" != true ]
    then
        ###
        # USER AREA
        ###

        # Ask User which Version he want to install:
        # We made a recalculation the result is the element 0 in the array FOLDER[0] is shown as Element 1. If the user type in the version this recalculation is reverted.
        echo "Which version do you want to install:"
        for (( i=1; i<=${#FOLDER[@]}; i++ ))
        do
            [ "${FOLDER[$i-1]}" = "backup" ] && continue
            [ "${FOLDER[$i-1]}" = "config" ] && continue
            [ "${FOLDER[$i-1]}" = "current" ] && continue
            [ "${FOLDER[$i-1]}" = ".travis" ] && continue
            [[ "${FOLDER[$i-1]}" = "0."* ]] && continue
            [[ "${FOLDER[$i-1]}" = "1.0.0"* ]] && continue
            [[ "${FOLDER[$i-1]}" = "1.0.1"* ]] && continue
            [[ "${FOLDER[$i-1]}" = "1.0.2"* ]] && continue
            [[ "${FOLDER[$i-1]}" = "1.1.0"* ]] && continue
            [ "${FOLDER[$i-1]}" = "$CURRENT_VERSION" ] || echo "[ ${i} ] - ${FOLDER[$i-1]}"
            [ "${FOLDER[$i-1]}" = "$CURRENT_VERSION" ] && echo "[ ${i} ] - ${FOLDER[$i-1]} (currently installed)"
        done
        echo

        # User setup the right version 
        input_sel=0
        while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
            read -rp "Please choose the version: " input_sel
        done
        # set new Version
        CURRENT_VERSION="${FOLDER[${input_sel}-1]}"

    else
        ###
        # CI AREA
        ###
        [ -z "${param_VERSION-}" ] && echo "No version parameter. Please call: '$0 [VERSION]'. Exit." && exit
        [ -d config ] || mkdir config || ( echo "Can not create directory config. Exit now" && exit 1 )
          [ -n "${SERVER_TAG-}" ] && echo "Change Tag for server ${SERVER_TAG-}..." && echo "MISP_CONTAINER_TAG=$SERVER_TAG" >> config/config.env
          [ -n "${PROXY_TAG-}" ] && echo "Change Tag for proxy ${PROXY_TAG-}..." && echo "PROXY_CONTAINER_TAG=$PROXY_TAG" >> config/config.env
          [ -n "${REDIS_TAG-}" ] && echo "Change Tag for redis ${REDIS_TAG-}..." && echo "REDIS_CONTAINER_TAG=$REDIS_TAG" >> config/config.env
          [ -n "${DB_TAG-}" ] && echo "Change Tag for db ${DB_TAG-}..." && echo "DB_CONTAINER_TAG=$DB_TAG" >> config/config.env
          [ -n "${MODULES_TAG-}" ] && echo "Change Tag for misp-modules ${MISP_MODULES_CONTAINER_TAG-}..." && echo "MISP_MODULES_CONTAINER_TAG=$MODULES_TAG" >> config/config.env
          [ -n "${ROBOT_TAG-}" ] && echo "Change Tag for robot ${ROBOT_TAG-}..." && echo "ROBOT_CONTAINER_TAG=$ROBOT_TAG" >> config/config.env
          [ -n "${MONITORING_TAG-}" ] && echo "Change Tag for monitoring ${MONITORING_TAG-}..." && echo "MONITORING_CONTAINER_TAG=$MONITORING_TAG" >> config/config.en
          echo "Config:"
          [ -f config/config.env ] && tail config/config.env
    fi

echo "Selected version: $CURRENT_VERSION..."

# Create Symlink to "current" Folder
    if [ -z "$CURRENT_VERSION" ]
    then
        echo "[Error] The script failed and no version could be selected. Exit now."
        exit
    else
        # create symlink for 'current' folder
        [ -L "$PWD/current" ] && echo "[OK] Delete symlink 'current'" && rm "$PWD/current"
        [ -f "$PWD/current" ] && echo "[Error] There is a file called 'current' please backup and delete this file first. Command: 'rm -v $PWD/current'" && exit
        [ -d "$PWD/current" ] && echo "[Error] There is a directory called 'current' please backup and delete this folder first. Command: 'rm -Rv $PWD/current'" && exit
        echo "[OK] Create symlink 'current' for the folder $CURRENT_VERSION" && ln -s "$CURRENT_VERSION" current
        # create symlink for backup
        [ -L "$PWD/current/backup" ] && echo "[OK] Delete symlink 'current/backup'" && rm "$PWD/current/backup"
        echo "[OK] Create symlink 'current/backup'" && ln -s "../backup" ./current/
        # create symlink for config
        [ -L "$PWD/current/config" ] && echo "[OK] Delete symlink 'current/config'" && rm "$PWD/current/config"
        echo "[OK] Create symlink 'current/config' " && ln -s "../config" ./current/

        # [ "$CI" == true ] || echo "start installation..."
        # [ "$CI" == true ] || sleep 1
        # [ "$CI" == true ] || make -C current install
    fi
