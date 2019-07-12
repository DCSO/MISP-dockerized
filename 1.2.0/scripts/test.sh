#!/bin/sh
set -eu


# Variables
NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
STARTMSG="${Light_Green}[TEST]${NC}"
AUTH_KEY=""

REPORT_FOLDER="$PWD/../.ci"
REPORT_FILE="$REPORT_FOLDER/reports/*.xml"

# Functions
echo (){
    command echo "$STARTMSG $*"
}


#
#   MAIN
#

# wait until misp-server is ready
MSG_3="####################################  started Apache2"
MSG_2="Your MISP-dockerized server has been successfully booted."
MSG_1="Your MISP docker has been successfully booted for the first time."
SLEEP_TIMER=5
while true
do
    [ -z "$(docker logs misp-server 2>&1 | grep "$MSG_3")" ] || break
    [ -z "$(docker logs misp-server 2>&1 | grep "$MSG_2")" ] || break
    [ -z "$(docker logs misp-server 2>&1 | grep "$MSG_1")" ] || break
    #wait x seconds
    echo "$(date +%T) -  wait until misp-server is ready. sleep $SLEEP_TIMER seconds..."
    docker logs --tail 10 misp-server
    command echo 
    sleep "$SLEEP_TIMER"
    # shellcheck disable=SC2004
    SLEEP_TIMER=$(( $SLEEP_TIMER + 5))
done

echo "################		Start Tests		###########################"
docker exec misp-robot bash -c "/srv/scripts/test.sh 2> /srv/MISP-dockerized-testbench/reports/error.txt"
[ ! -d "$REPORT_FOLDER" ] && mkdir "$REPORT_FOLDER"
docker cp misp-robot:/srv/MISP-dockerized-testbench/reports/. "$REPORT_FOLDER/"
echo "#################################################################"
echo "For the report output: cat $REPORT_FILE"
echo "#################################################################"


