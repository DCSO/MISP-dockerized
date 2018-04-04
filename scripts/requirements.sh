#!/bin/bash

# Variables
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
STATUS="OK"
DOCKER_SOCK="/var/run/docker.sock"
# Load Variables from Configuration
source $SCRIPTPATH/../config/.env

# to add options to the echo command
    echo () {
        command echo -e "$@" 
    }

# check_URL: check a url with 2 parameters: URL_BASE=github.com & URL_PROTOCOL=http/https
    function check_URL(){
        #set -xv
        URL_BASE="$1"
        URL_PROTOCOL="$2"
        [ $USE_PROXY == yes ] && PROXY=" -x $HTTP_PROXY"
        #COMMAND="curl -vs -o /dev/null -I --connect-timeout 5 -m 7 $PROXY $URL_PROTOCOL://$URL_BASE 2>&1"
        COMMAND=`curl --fail --silent --show-error http://www.example.com/ > /dev/null -x 127.0.0.1:8080 2>&1`
        VAR="$($COMMAND)"
        echo "\n\necho:\n $COMMAND"
        exit 1


        #if [ -z "$($COMMAND)" ]
        if [ ! -z "`$COMMAND | grep 'Connection refused'`" ]
            then
                STATUS="FAIL"
                echo "[FAIL] Check: $URL_PROTOCOL://$URL_BASE; \tResult: Connection Refused."
            else
                echo "[OK] Check: $URL_PROTOCOL://$URL_BASE; \tResult: Connection available."
        fi
    }

####################    Start Script    ##############################

#
#   Check DOCKER
#
    if [ -z "$(which docker)" ] 
        then
            STATUS="FAIL"
            echo "[FAIL] Docker is not Installed. \tPlease install it first!" 
        else
            echo "[OK] Docker is Installed. \t\tOutput: $(docker -v)"   
    fi

#
#   Check GIT
#
    if [ -z "$(which git)" ] 
        then
            STATUS="FAIL"
            echo -e "[FAIL] Git is not Installed. \t\t\tPlease install it first!"
        else
            echo -e "[OK] Git is Installed. \t\t\tOutput: $(git --version)"
    fi

#
#   check DOCKER-COMPOSE
#
#   dependency disabled, because misp-robot does docker-compose
    # if [ -z "$(which docker-compose)" ] 
    #     then
    #         STATUS="FAIL"
    #         echo -e "[FAIL] Docker-compose is not Installed. \tPlease install it first!"
    #     else
    #         echo -e "[OK] Docker-compose is installed. \tOutput: $(docker-compose -v)"

    # fi

#
# CHECK required URLs
#
    #check hub.docker.com
    #check_URL hub.docker.com https
    # check github
    #check_URL github.com https

###############################  USER CHECKS    #########################
echo "" # Empty Line for a better overview.

#
#   Check user part of docker group
#
    if [ $(whoami) != "root" ]
        then
            # if user is not root then check if it is in dokcer group
            if [ -z "$(cat /etc/group|grep docker|grep `whoami`)" ]
                then
                    STATUS="FAIL"
                    # user not part of docker group
                    echo "[FAIL] User '$(whoami)' isn't part of the docker group. -> Try: sudo usermod -aG docker $(whoami)"
                else
                    # user is in docker group
                    echo "[OK] User '$(whoami)' is part of the docker group."
            fi
        else
            echo "[OK] User '$(whoami)' has root rights."
    fi
#
#   Check docker.sock
#
    if [ ! -z "$(docker ps 2>&1|grep 'permission denied')" ]
        then
            STATUS="FAIL"
            echo "[FAIL] User '$(whoami)' hasn't access to Docker."
        else
            # user is in docker group
            echo "[OK] User '$(whoami)' has access to Docker."
    fi

###############################  FILE CHECKS    #########################

#
#   Check Write permissions
#
echo
[ ! -d ./config/ssl ] && echo -n "create config directory..." && mkdir -p ./config/ssl && echo "finished." 
[ ! -d ./backup ] && echo -n "create backup directory..." && mkdir ./backup && echo "finished."

function check_folder(){
    FOLDER="$1"
    if [ ! -e "$FOLDER" ]
            then
                STATUS="FAIL"
                echo "[FAIL] Can't create '$FOLDER' Folder."
            else
                # user is in docker group
                echo "[OK] Folder $FOLDER exists."
                touch $FOLDER/test
                if [ ! -e $FOLDER/test ]
                    then
                        STATUS="FAIL"
                        echo "[FAIL] No write permissions in '$FOLDER'. Please ensure that user '${whoami}' has write permissions.'"
                    else
                        echo "[OK] Testfile in '$FOLDER' can be created."
                        rm $FOLDER/test
                fi
        fi
}

check_folder "config"
check_folder "config/ssl"
check_folder "backup"

#################################################################

# END Result
    echo "\nEnd result:"
    if [ $STATUS == "FAIL" ]
        then
            echo "[$STATUS] at least one Error is occured.\n"
            exit 1
        else
            echo "[$STATUS] no Error is occured.\n"
            exit 0
    fi