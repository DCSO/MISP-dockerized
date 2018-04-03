#!/bin/bash

######################  START GLOBAL  ####################################
#exit on error and pipefail
#set -o pipefail
#########
MISP_dockerized_repo="/srv/misp-dockerized"
USE_CURL=y                                          # use curl or wget?
export LC_ALL=C                                     # export LC_ALL as language C
DATE=$(date +%Y-%m-%d_%H_%M_%S)                     # current date
BRANCH=$(cd $MISP_dockerized_repo; git rev-parse --abbrev-ref HEAD)           # my branch
TAGS=""                                             # existing commits
myCOMMIT="$(cd $MISP_dockerized_repo; git log --format="%H"|head -1)"         # my currently installed commit
myTAG=""                                            # my current installed tag
myTAG_TIMESTAMP="$(cd $MISP_dockerized_repo; git log --format="%ct"|head -1)" # Date of the current installed tag 
NEW_TAG=""                                          # my new tag after update
declare -A TAG_SELECTION                            # declare an Array
######################  END GLOBAL  ####################################


# Function: to compare PARAM1 with PARAM2 if PARAM1 > PARAM2
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Function: Search in git repo for all existing TAGs
function search_existing_tags(){
  echo -n "Search existing Tags @ github..."
  TAGS="$(git tag -l|tail +2)"
  echo "Finished."
}

# Function: Search in git repo my Installed Tag
function search_myTag(){
  search_existing_tags
  echo -n "Check myTag..."
  for TAG in $TAGS
  do
    COMMIT=$(git log "$TAG" --format="%H"|head -1)
    if [ "$myCOMMIT" == "$COMMIT" ]; then myTAG+="$TAG "; fi
  done
  echo "Finished. Current installed release tag: $myTAG"
}

# Function: To which Tag should we update?
function update_2_tag(){
  search_myTag
  echo -n "Check if update is possible..."
  # Set Var
  i=1
  # search all TAGS newer then the current one
  for TAG in $TAGS; do
      CURRENT_TAG_TIMESTAMP="$(git log $TAG --format="%ct"|head -1)"
      if [ $CURRENT_TAG_TIMESTAMP > $myTAG_TIMESTAMP ]; then continue;fi; # only show newer release tags!
      #echo "[ ${i} ] - ${TAG}"
      TAG_SELECTION[${i}]="${TAG}"
      ((i++))
  done
  # check if Update is possible!
  if [ ${#TAG_SELECTION[@]} = 0 ]; then echo -e "Finished. No Update available. I will exit.\n";exit 1;fi;
  echo
  # List all Tags as parameter
  echo "The following Tags are available for you:"
  for i in ${#TAG_SELECTION[@]}
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
