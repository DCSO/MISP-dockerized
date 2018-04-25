#!/bin/bash

# Variables
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
STATUS="OK"
DOCKER_SOCK="/var/run/docker.sock"
# Load Variables from Configuration
source $SCRIPTPATH/../.env

# to add options to the echo command
    echo () {
        command echo -e "$@" 
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
# CHECK required URLs
#
echo
# check_URL: check a url with 2 parameters: URL_BASE=github.com & URL_PROTOCOL=http/https
function check_URL(){
    #set -xv
    URL="$1"
    [ "$USE_PROXY" == "yes" ] && PROXY=" -x $HTTP_PROXY"
    OPTIONS="-vs --connect-timeout 5 -m 7 $PROXY"
    COMMAND="$(curl $OPTIONS $URL 2>&1|grep 'Connected to')"
    
    if [ -z "$COMMAND" ]
        then
            STATUS="FAIL"
            echo "[FAIL] Check: $URL"
            echo "       Result: Connection not available."
        else
            echo "[OK]   Check: $URL"
            echo "       Result: $COMMAND."
    fi
}
#check hub.docker.com
check_URL https://docker.io
# check github
check_URL https://github.com/DCSO/misp-dockerized

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
[ ! -d ./config/ssl ] && echo -n "create config directory..." && mkdir -p ./config/ssl  && echo "finished." 
[ ! -d ./backup ]     && echo -n "create backup directory..." && mkdir ./backup         && echo "finished."

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



###############################  CERT CHECKS    #########################

#
#   Check SSL
#
echo
if [ ! -f ./config/ssl/key.pem -a ! -f ./config/ssl/cert.pem ]; then
    read -r -p "[WARN] No certificate found. Should we create a self-signed certificate? [Y/n] " -ei "y" response
    case $response in
    [yY][eE][sS]|[yY])
        echo "[OK] We create a self-signed certificate in the volume."
        echo "     To change the SSL certificate and private key later: "
        echo "     1. save certificate into:      $PWD/config/ssl/cert.pem"
        echo "     2. save private keyfile into:  $PWD/config/ssl/key.pem"
        echo "     3. do:                         make change-ssl"
        read -r -p "     continue with ENTER"     
        echo
        echo
        ;;
    *)
        STATUS="FAIL"
        echo "[FAIL] No certificate file exists. Please save your cert at: $PWD/config/ssl/cert.pem" 
        echo "[FAIL] No certificate key exists. Please save your key at:   $PWD/config/ssl/key.pem"
        echo
        ;;
    esac
fi


###############################  END Result    #########################
echo "End result:"
if [ $STATUS == "FAIL" ]
    then
        echo "[$STATUS] at least one Error is occured."
        echo
        exit 1
    else
        echo "[$STATUS] no Error is occured."
        echo
        exit 0
fi