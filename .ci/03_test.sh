#!/bin/sh
set -eu

# https://stackoverflow.com/questions/13068152/grep-exit-codes-in-makefile#13069387

# Variables
REPORT_FOLDER="reports"
# REPORT_FILE="$REPORT_FOLDER/*.xml"


#
#   MAIN
#

echo "################		Start Tests		###########################"

# Create report directory if not exists
    if [ ! -d "$REPORT_FOLDER" ]; then mkdir "$REPORT_FOLDER"; fi ;
# Execute Test script from misp-robot
    docker exec misp-robot bash -c "/srv/scripts/test.sh"
# Check return value
    retVal=$?
# Copy report files
    docker cp misp-robot:/srv/MISP-dockerized-testbench/reports/. "$REPORT_FOLDER"/
    docker cp misp-robot:/srv/MISP-dockerized-testbench/logs/. "$REPORT_FOLDER"/
# Check if Test was succesful or not
if [ $retVal != 0 ]; 
then 
    sleep 5
    echo
    echo "[ERROR] Test was not successful. Output Logs from Container and exit.";
    echo
    echo "misp-proxy:"; docker logs misp-proxy --tail 20; echo "";
    echo "misp-server:"; docker logs misp-server --tail 20; echo ""; 
    echo "misp-modules:" ; docker logs misp-modules --tail 20; echo "";
    echo "error output:"; head -n 20 reports/error.txt; echo "";
    echo "[ERROR] Test was not successful."; echo "";
    echo "################		End Tests		###########################"
    exit 1 ;
else 
    echo
    echo "[Info] Test was successful";  
    echo
    echo "################		End Tests		###########################"
    exit 0; 
fi