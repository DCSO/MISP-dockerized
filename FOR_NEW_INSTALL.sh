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
    check_version_legacy (){
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
    
    check_version(){
        # This function checks the current link to which version it goes
        # https://www.linuxquestions.org/questions/linux-software-2/how-to-find-symlink-target-name-in-script-364971/
        CURRENT_VERSION="$(ls -l current | awk '{print $11}')"
    }

    # if current symlink exists
    [ -L ./current ] && [ -z "$CURRENT_VERSION" ] && check_version
    # if current symlink not exists
    [ -L ./current ] && [ -z "$CURRENT_VERSION" ] && check_version_legacy


############### START MAIN ###################


# check which version should be installed
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
        [ -z "${param_VERSION-}" ] && echo "No version parameter. Please call: '$0 [VERSION]'. Exit." && exit 1
    fi

# Echo which version should be installed
  echo "Selected version: $CURRENT_VERSION..."

# Create Symlink to "current" Folder
    if [ -z "$CURRENT_VERSION" ]
    then
        echo "[Error] The script failed and no version could be selected. Exit now."
        exit 1
    else
        # create symlink for 'current' folder
        [ -L "$PWD/current" ] && echo "[OK] Delete symlink 'current'" && rm "$PWD/current"
        [ -f "$PWD/current" ] && echo "[Error] There is a file called 'current' please backup and delete this file first. Command: 'rm -v $PWD/current'" && exit
        [ -d "$PWD/current" ] && echo "[Error] There is a directory called 'current' please backup and delete this folder first. Command: 'rm -Rv $PWD/current'" && exit
        echo "[OK] Create symlink 'current' for the folder $CURRENT_VERSION" && ln -s "$CURRENT_VERSION" current
        
        # Create config and backup folder if it not exists
        [ -d ./backup ] && mkdir backup
        [ -d ./config ] && mkdir config

        # create symlink for backup
        [ -L "$PWD/current/backup" ] && echo "[OK] Delete symlink 'current/backup'" && rm "$PWD/current/backup"
        echo "[OK] Create symlink 'current/backup'" && ln -s "../backup" ./current/
        
        # create symlink for config
        [ -L "$PWD/current/config" ] && echo "[OK] Delete symlink 'current/config'" && rm "$PWD/current/config"
        echo "[OK] Create symlink 'current/config' " && ln -s "../config" ./current/
    fi
