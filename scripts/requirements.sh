#!/bin/bash

# check if this is an automate build not ask any questions
[ "$CI" = "true" ] && AUTOMATE_BUILD="true"

# Variables
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
STATUS="OK"
DOCKER_SOCK="/var/run/docker.sock"


# Load Variables from Configuration
[ -e "$SCRIPTPATH/../.env" ] && source $SCRIPTPATH/../config/config.env

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
    OPTIONS="-vs --connect-timeout 60 -m 30 $PROXY"
    COMMAND="$(curl $OPTIONS $URL 2>&1|grep 'Connected to')"
    
    if [ -z "$COMMAND" ]
        then
            echo "[WARN] Check: $URL"
            echo "       Result: Connection not available."
            [ "$AUTOMATE_BUILD" == "true" ] || read -r -p "     continue with ENTER"  
        else
            echo "[OK]   Check: $URL"
            echo "       Result: $COMMAND."
    fi
}

check_URL https://misp.dcso.de
check_URL https://dockerhub.dcso.de/v2/
check_URL https://github.com/DCSO/misp-dockerized
# check_URL https://docker.io
# check_URL https://registry-1.docker.io/
# check_URL https://auth.docker.io
# check_URL https://production.cloudflare.docker.com

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
[ ! -d ./config/ssl ]     && echo -n "create config and config/ssl directory..." && mkdir -p ./config/ssl  && echo "finished." 
[ ! -d ./config/smime ]   && echo -n "create config/smime directory..."          && mkdir ./config/smime         && echo "finished."
[ ! -d ./config/pgp ]     && echo -n "create config/pgp directory..."            && mkdir ./config/pgp         && echo "finished."
[ ! -d ./backup ]         && echo -n "create backup directory..."                && mkdir ./backup         && echo "finished."

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
check_folder "config/pgp"
check_folder "config/smime"
check_folder "backup"



###############################  CERT CHECKS    #########################




#
#   Check SSL
#
echo
if [ ! -f ./config/ssl/key.pem -a ! -f ./config/ssl/cert.pem ]; then
    
    [ "$AUTOMATE_BUILD" == "true" ] || read -r -p "[WARN] No SSL certificate found. Should we create a self-signed certificate? [Y/n] " -ei "y" response
    [ "$AUTOMATE_BUILD" == "true" ] && echo "[WARN] No SSL certificate found. Should we create a self-signed certificate? [Y/n] y" && response="y"
    case $response in
    [yY][eE][sS]|[yY])
        echo "[OK] We create a self-signed certificate in the volume."
        echo "     To change the SSL certificate and private key later: "
        echo "     1. save certificate into:      $PWD/config/ssl/cert.pem"
        echo "     2. save private keyfile into:  $PWD/config/ssl/key.pem"
        echo "     3. do:                         make change-ssl"
        [ "$AUTOMATE_BUILD" == "true" ] || read -r -p "     continue with ENTER"     
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

###############################  SMIME CHECKS    #########################
echo
if [ ! -f ./config/smime/key.pem -a ! -f ./config/smime/cert.pem ]; then
    [ "$AUTOMATE_BUILD" == "true" ] || read -r -p "[WARN] No S/MIME certificate found. Would you start with S/MIME? [y/N] " -ei "n" response
    [ "$AUTOMATE_BUILD" == "true" ] && echo "[WARN] No S/MIME certificate found. Would you start with S/MIME? [y/N] n" && response="n"
    case $response in
    [yY][eE][sS]|[yY])
        STATUS="FAIL"
        echo "[FAIL] Please save a S/MIME Certificate and the private Key."
        echo "     1. save certificate into:      $PWD/config/smime/cert.pem"
        echo "     2. save private keyfile into:  $PWD/config/smime/key.pem"
        read -r -p "     continue with ENTER"     
        echo
        echo
        exit 1
        ;;
    *)
        echo "[OK] No S/MIME want be used. If you want to use S/MIME Later:"
        echo "     1. Please save your cert at:  $PWD/config/smime/cert.pem" 
        echo "     2. Please save your key  at:  $PWD/config/smime/key.pem"
        echo "     3. do:                        make config-smime"
        echo
        ;;
    esac
fi

###############################  PGP CHECKS    #########################
echo
if [ ! -f ./config/pgp/private.key -a ! -f ./config/pgp/public.key ]; then
    [ "$AUTOMATE_BUILD" == "true" ] || read -r -p "[WARN] No PGP key found. Should we create a pgp key? [Y/n] " -ei "y" response
    [ "$AUTOMATE_BUILD" == "true" ] && echo "[WARN] No PGP key found. Should we create a pgp key? [Y/n] y" && response="y"
    case $response in
    [yY][eE][sS]|[yY])
        ENTROPY=$(cat /proc/sys/kernel/random/entropy_avail)
        if [[ $ENTROPY -gt 1000 ]]
        then
            echo "[OK] We create a pgp key in the volume. It will be saved to: $PWD/config/pgp/"
            touch ./config/pgp/pgp.enable
        else
            echo "[FAIL] Sorry but we can't create your pgp key in the volume. Your entropy ($ENTROPY >= 1000) is to low. Please create your PGP key outside of docker."
            # Bringt STATUS in Fail State if it is not automated
            [ "$AUTOMATE_BUILD" == "true" ] || STATUS="FAIL"
        fi
        echo "     To replace the PGP public and private file later: "
        echo "     1. save public key into:      $PWD/config/pgp/public.key"
        echo "     2. save private key into:  $PWD/config/pgp/private.key"
        echo "     3. do:                         make config-pgp"
        [ "$AUTOMATE_BUILD" == "true" ] || read -r -p "     continue with ENTER"     
        echo
        echo
        ;;
    *)
        STATUS="FAIL"
        # echo "     To change the PGP public and private file later: "
        # echo "     1. save public key into:      $PWD/config/pgp/public.key"
        # echo "     2. save private key into:  $PWD/config/pgp/private.key"
        # echo "     3. do:                         make config-pgp"
        # [ "$AUTOMATE_BUILD" = "true" ] || read -r -p "     continue with ENTER" 
        echo "[FAIL] No certificate file exists. Please save your cert at: $PWD/config/pgp/public.key" 
        echo "[FAIL] No certificate key exists.  Please save your key at:   $PWD/config/pgp/private.key"
        echo
        ;;
    esac
fi

###############################  DCSO Check    #########################
FILE="./config/use_secure_DCSO_Docker_Registry.enable"

[ "$AUTOMATE_BUILD" == "true" ] || read -r -p "Are you a DCSO TI MISP Customer? [Y/n] " -ei "y" response
# for internal GITLAB:
[ "$AUTOMATE_BUILD" == "true" ] && response="y"
# for travis:
[ "$TRAVIS" == "true" ] && response="n"

case $response in
[yY][eE][sS]|[yY])
    [ "$AUTOMATE_BUILD" == "true" ] || read -r -p "Do you want to load the MISP containers from secure DCSO Registry? [Y/n] " -ei "y" response
    case $response in
    [yY][eE][sS]|[yY])
        touch $FILE
        echo "We switched the container repository to secure DCSO registry."
        echo "      If you want to use the public one from hub.docker.com, please delete $FILE and 'make install'"
        [ "$AUTOMATE_BUILD" == "true" ] || read -r -p "     continue with ENTER"     
        ;;
    *)
        rm -f $FILE
        ;;
    esac
    echo
    echo
    ;;
*)
    rm -f $FILE
    ;;
esac



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
##########################################################################