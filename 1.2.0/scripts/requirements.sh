#!/bin/bash

# Variables
# shellcheck disable=SC2164
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
STATUS="OK"
#DOCKER_SOCK="/var/run/docker.sock"


# Load Variables from Configuration
# shellcheck disable=SC1090
[ -f "$SCRIPTPATH/../config/config.env" ] && source "$SCRIPTPATH/../config/config.env"

# Load functions
# shellcheck disable=SC1090
[ -f "$SCRIPTPATH/functions.sh" ] && source "$SCRIPTPATH/functions.sh"

# to add options to the echo command
    echo () {
        command echo -e "$@" 
    }

####################    Start Script    ##############################

#
#   Check Dependencies
#
func_check_docker
func_check_git

echo

#
#   Check URLs
#
func_check_URL https://misp.dcso.de
func_check_URL https://dockerhub.dcso.de/v2/
func_check_URL https://github.com/DCSO/misp-dockerized
func_check_URL https://github.com/misp/misp

###############################  USER CHECKS    #########################
echo "" # Empty Line for a better overview.

#
#   Check user part of docker group
#
    if [ "$(whoami)" != "root" ]
        then
            # if user is not root then check if it is in docker group
            if [ -z "$(grep docker /etc/group|grep "$(whoami)")" ]
                then
                    STATUS="FAIL"
                    # user not part of docker group
                    echo "[FAIL] User '$(whoami)' is not part of the 'docker' group. -> Try: sudo usermod -aG docker $(whoami)"
                else
                    # user is in docker group
                    echo "[OK] User '$(whoami)' is part of the 'docker' group."
            fi
        else
            echo "[OK] User '$(whoami)' is root."
    fi
#
#   Check docker.sock
#
    if [ ! -z "$(docker ps 2>&1|grep 'permission denied')" ]
        then
            STATUS="FAIL"
            echo "[FAIL] User '$(whoami)' has not access to Docker daemon."
        else
            # user is in docker group
            echo "[OK] User '$(whoami)' has access to Docker daemon."
    fi

###############################  FILE CHECKS    #########################

#
#   Check Write permissions
#
echo
[ ! -d ./config/ssl ]     && echo -n "Create config and config/ssl directory..." && mkdir -p ./config/ssl  && echo "finished." 
[ ! -d ./config/smime ]   && echo -n "Create config/smime directory..."          && mkdir ./config/smime         && echo "finished."
[ ! -d ./config/pgp ]     && echo -n "Create config/pgp directory..."            && mkdir ./config/pgp         && echo "finished."
[ ! -d ./backup ]         && echo -n "Create backup directory..."                && mkdir ./backup         && echo "finished."

check_folder_write "config"
check_folder_write "config/ssl"
check_folder_write "config/pgp"
check_folder_write "config/smime"
check_folder_write "backup"

###############################  SSL CERT CHECKS    #########################
echo
if [ ! -f "./config/ssl/$SSL_KEY" ] && [ ! -f "./config/ssl/$SSL_CERT" ]; then
    warn "[WARN] No SSL certificate found. We create a self-signed certificate in the volume."
    warn "     To change the SSL certificate and private key later: "
    warn "     1. Please save your certificate in:      $PWD/config/ssl/$SSL_CERT"
    warn "     2. Please save your private keyfile in:  $PWD/config/ssl/$SSL_KEY"
    warn "     3. do:                         make config-ssl"
    echo
    echo
fi

###############################  SMIME CHECKS    #########################
echo
if [ ! -f "./config/smime/$SMIME_KEY" ] && [ ! -f "./config/smime/$SMIME_CERT" ]; then
    warn "[WARN] No S/MIME certificate found."
    warn "     1. Please save your certificate in:  $PWD/config/smime/$SMIME_CERT" 
    warn "     2. Please save your private key  in:  $PWD/config/smime/$SMIME_KEY"
    warn "     3. Do:                        make config-smime"
    echo
fi

###############################  PGP CHECKS    #########################
echo
if [ ! -f "./config/pgp/*.asc" ]; then
    warn "[WARN] No PGP key found."
    warn "     To replace the PGP public and private file later: "
    warn "     1. Please save your public/private key in:      $PWD/config/pgp/$PGP_KEYFILE"
    warn "     2. Do:                                          make config-pgp"
    echo
    echo
fi

###############################  END Result    #########################
echo "End result:"
if [ $STATUS == "FAIL" ]
    then
        error "[$STATUS] At least one error is occured."
        echo
        exit 1
    else
        echo "[$STATUS] No error is occured."
        echo
        exit 0
fi
##########################################################################