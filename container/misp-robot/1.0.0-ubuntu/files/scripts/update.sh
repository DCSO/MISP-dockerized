#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )" # path of the script
MISP_dockerized_path="$SCRIPTPATH/../misp-dockerized/"

# Include functions source file:
[ -e $SCRIPTPATH/functions.sh ] && source $SCRIPTPATH/functions.sh
[ -e $MISP_dockerized_path/config/.env ] && source $MISP_dockerized_path/config/.env

# check if required components exists
function check_components(){
  echo -n "Check requirements..."
  for bin in docker-compose docker git awk sha1sum; do
    if [[ -z $(which ${bin}) ]]; then echo "Cannot find ${bin}, exiting..."; exit 1; fi
  done
  # check curl
  if [[ -z $(which curl) ]]; 
    then 
      echo "Cannot find curl, i check for wget";
      if [[ -z $(which wget) ]]; then echo "Cannot find wget and curl, exiting..."; exit 1;
      else
        # set variable to not use curl and use wget.
        USE_CURL=n;  fi
  fi
  if grep --help 2>&1 | head -n 1 | grep -q -i "busybox"; then echo "BusybBox grep detected, please install gnu grep, \"apk add --no-cache --upgrade grep\""; exit 1; fi
  if cp --help 2>&1 | head -n 1 | grep -q -i "busybox"; then echo "BusybBox cp detected, please install coreutils, \"apk add --no-cache --upgrade coreutils\""; exit 1; fi
  echo "Finished."
}

#
# DCSO Upgrade Functions
#
function upgrade_from_v.2.4.88-beta.1(){
  ENV_FILE=${SCRIPTPATH/../.env}
  MISP_CONFIG=${SCRIPTPATH/../config/misp.conf.yml}
  [[ ! -f "$ENV_FILE" ]] && { echo ".env is missing"; exit 1;}
  [[ ! -f "$MISP_CONFIG" ]] && { echo "MISP config is missing"; exit 1;}
}

function upgrade_to_v2.4.88-beta.2(){ 
  echo "Upgrading to v2.4.88-beta.2..."; 
  upgrade_to_v2.4.88.beta.1 
  echo "Upgrading to v2.4.88-beta.2...Finished"; 
}

function upgrade_to_v2.4.88-beta.3(){ 
  echo "Upgrading to v2.4.88-beta.2..."; 

  ENV_FILE="${MISP_dockerized_path}/config/.env"
  MISP_CONFIG="${MISP_dockerized_path}/config/misp.conf.yml"
  [[ ! -f "$ENV_FILE" ]] && { echo ".env is missing"; exit 1;}
  [[ ! -f "$MISP_CONFIG" ]] && { echo "MISP config is missing"; exit 1;}
  
  # change NGINX User to change from ubuntu www-data to alpine nginx user
  sed -e -i '/^user/s/www-data/nginx/g' /srv/misp-proxy/GLOBAL_nginx_common
  docker restart misp-proxy



  echo "Upgrading to v2.4.88-beta.2...Finished"; 
}

function upgrade_to_v2.4.89-beta.1(){

}

##########################  MAIN  ##########################
echo
echo "#########################################################"
echo "############### Starting Update Script  #################"
echo "# Description: This Script update the MISP Environment. #"
echo "#########################################################"

check_components  # check if all binaries existing
# To which tag should we update?
update_2_tag      
# what we need to do for the Update:
case "$NEW_TAG" in
  v2.4.88-beta.1)
    echo "$NEW_TAG is the first Version and we don't support Downgrades."
    ;;
  v2.4.88-beta.2)
    upgrade_to_v2.4.88-beta.2
    ;;
  v2.4.88-beta.3)
    upgrade_to_v2.4.88-beta.2
    upgrade_to_v2.4.88-beta.3
    ;;
esac

exit 1;
