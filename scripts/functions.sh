#!/bin/bash

######################  START GLOBAL  ####################################
#exit on error and pipefail
set -o pipefail
#########
USE_CURL=y                                      # use curl or wget?
export LC_ALL=C                                 # export LC_ALL as language C
DATE=$(date +%Y-%m-%d_%H_%M_%S)                 # current date
BRANCH=$(git rev-parse --abbrev-ref HEAD)       # my branch
TAGS=""                                         # existing commits
myCOMMIT=$(git log -1|head -1)                  # my currently installed commit
myTAG=""                                        # my current installed tag
NEW_TAG=""                                      # my new tag after update
declare -A TAG_SELECTION                        # declare an Array
######################  END GLOBAL  ####################################

# Function: to compare PARAM1 with PARAM2 if PARAM1 > PARAM2
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Function: Search in git repo for all existing TAGs
function search_existing_tags(){
  TAGS="$(git tag -l|tail +2)"
}

# Function: Search in git repo my Installed Tag
function search_myTag(){
  search_existing_tags
  for TAG in $TAGS
  do
    COMMIT=$(git show "$TAG"|head -1)
    if [ "$myCOMMIT" == "$COMMIT" ]; then myTAG+="$TAG"; break; fi
  done
}

# Function: To which Tag should we update?
function update_2_tag(){
  search_myTag
  echo "You have currently installed Tag: $myTAG"
  # Set Var
  i=1
  # List all Tags as parameter
  for TAG in $TAGS; do
      if version_gt $myTAG $TAG; then continue;fi # show only versions higher than mine
      echo "[ ${i} ] - ${TAG}"
      TAG_SELECTION[${i}]="${TAG}"
      ((i++))
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
