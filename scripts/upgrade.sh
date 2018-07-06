#!/bin/bash
set -ex

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )" # path of the script
MISP_dockerized_path="$SCRIPTPATH/../"


#########
USE_CURL=y                                          # use curl or wget?
export LC_ALL=C                                     # export LC_ALL as language C
DATE=$(date +%Y-%m-%d_%H_%M_%S)                     # current date
BRANCH=$(pushd $MISP_dockerized_repo; git rev-parse --abbrev-ref HEAD)           # my branch
TAGS=""                                             # existing commits
myCOMMIT="$(pushd $MISP_dockerized_repo; git log --format="%H"|head -1)"         # my currently installed commit
myTAG=""                                            # my current installed tag
myTAG_TIMESTAMP="$(pushd $MISP_dockerized_repo; git log --format="%ct"|head -1)" # Date of the current installed tag 
NEW_TAG=""                                          # my new tag after update
declare -A TAG_SELECTION                            # declare an Array
######################  END GLOBAL  ####################################


# Import configs:
[ -f $MISP_dockerized_path/.env ] && source $MISP_dockerized_path/.env
[ -f $MISP_dockerized_path/config/config.env ] && source $MISP_dockerized_path/config/config.env

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

# Function: check if a binary is installed
function check_components(){
  # This Function checks all binaries and also curl and wget if they are installed.
  echo -n "Check installed software..."
  for bin in $@; do
    # check curl
    if [[ -z $(which curl) ]]; 
      then 
        echo "Cannot find curl, i check for wget";
        if [[ -z $(which wget) ]]; then echo "Cannot find wget and curl, exiting..."; exit 1;
        else
          # set variable to not use curl and use wget.
          USE_CURL=n;  fi
    fi
    # for all other binaries:
    if [[ -z $(which ${bin}) ]]; then echo "Cannot find ${bin}, exiting..."; exit 1; fi
  done
  
  # Busybox Solutions
  if grep --help 2>&1 | head -n 1 | grep -q -i "busybox"; then echo "BusybBox grep detected, please install gnu grep, \"apk add --no-cache --upgrade grep\""; exit 1; fi
  if cp --help 2>&1 | head -n 1 | grep -q -i "busybox"; then echo "BusybBox cp detected, please install coreutils, \"apk add --no-cache --upgrade coreutils\""; exit 1; fi
  echo "Finished."
}

# Function: to compare PARAM1 with PARAM2 if PARAM1 > PARAM2
function version_gt() { 
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; 
}

# Function: Search in git repo for all existing TAGs
function search_existing_tags(){
  echo -n "Search existing tags in MISP-dockerized github repository ..."
  TAGS="$(git tag -l)"
  echo "Finished."
}

# Function: Search in git repo my Installed Tag
function search_myTag(){
  echo -n "Check current installed tag..."
  for TAG in $TAGS
  do
    COMMIT=$(git log "$TAG" --format="%H"|head -1)
    if [ "$myCOMMIT" == "$COMMIT" ]; then myTAG+="$TAG "; fi
  done
  echo "Finished. Current installed release tag: $myTAG"
  echo "$myTag" > config/MISP-dockerized_tag.old
}

# Function: To which Tag should we update?
function update_2_which_tag(){
  echo -n "Check if update is possible..."
  # Set Var
  i=1
  # search all TAGS newer then the current one
  for TAG in $TAGS; do
      CURRENT_TAG_TIMESTAMP="$(git log $TAG --format="%ct"|head -1)"
      if [ $CURRENT_TAG_TIMESTAMP -lt $myTAG_TIMESTAMP ] ; then continue;fi; # only show newer release tags!
      TAG_SELECTION[${i}]="${TAG}"
      ((i++))
  done
  # check if Update is possible!
  if [ ${#TAG_SELECTION[@]} = 0 ]; then echo "Finished. No Update available. I will exit.";echo;exit 0;fi;
  echo
  
  # List all Tags as parameter
  echo "The following Tags are available for you:"
  for (( i=1; i<=${#TAG_SELECTION[@]}; i++ ))
  do
    echo "[ ${i} ] - ${TAG_SELECTION[$i]}"
  done
  echo
  
  # set and check input var
  input_sel=0
  while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
    read -p "Select a Tag to Update: " input_sel
  done
  
  # set new Tag
  NEW_TAG="${TAG_SELECTION[${input_sel}]}"
}

function start_backup(){
  echo "Start Backup..."
  make backup-all
  echo "Backup...Finished"
}

#############################################
# DCSO Upgrade Functions
#############################################
function upgrade_2_new_version(){
  # Start Backup
  start_backup
  # switch git repo
  git checkout $NEW_TAG
  # make start
  make start
  echo "Upgrade from '$myTAG' to '$NEW_TAG' is finished."
}



###################################################################
##########################  MAIN  #################################
echo
echo "############### Starting Update Script  #################"
echo "# Description: This Script update the MISP Environment. #"
echo "#########################################################"

# CHECK required URLs
check_URL https://dockerhub.dcso.de
check_URL https://github.com/DCSO/misp-dockerized

# check if all binaries existing
check_components docker git awk sha1sum 

# search all existing tags in repo
search_existing_tags

# what is your current tag
search_myTag

# To which tag should we update?
update_2_which_tag      

# Upgrade
upgrade_2_new_version

# exit without failure
exit 0;
