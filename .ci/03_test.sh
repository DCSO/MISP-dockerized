#!/bin/sh

# https://stackoverflow.com/questions/13068152/grep-exit-codes-in-makefile#13069387

echo "################		Start Tests		###########################"

# Create report directory if not exists
if [ ! -d reports ]; then mkdir reports; fi ;

# Execute Test script from misp-robot
[ "${CI-}" = "true" ] && echo "wait 30 seconds..." && sleep 10
[ "${CI-}" = "true" ] && echo "wait 20 seconds..." && sleep 10
[ "${CI-}" = "true" ] && echo "wait 10 seconds..." && sleep 10
docker exec misp-robot bash -c "/srv/scripts/test.sh" 2> reports/error.txt
# Check return value
retVal=$?

# Copy report files
docker cp misp-robot:/srv/MISP-dockerized-testbench/reports/. reports/ ;\

# Check if Test was succesful or not
if [ $retVal != 0 ]; 
then 
    echo "";
    echo "[ERROR] Test was not successful. Output Logs from Container and exit.";
    echo "";
    echo "error output:"; head -n 15 reports/error.txt; echo "";
    echo "misp-proxy:"; docker logs misp-proxy --tail 20; echo "";
    echo "misp-server:"; docker logs misp-server --tail 20; echo ""; 
    echo "misp-modules:" ; docker logs misp-modules --tail 20; echo "";
    echo "[ERROR] Test was not successful."; echo "";
    echo "################		End Tests		###########################"
    exit 1 ;
else 
    echo "";
    echo "[Info] Test was successful";  echo "";
    echo "################		End Tests		###########################"
    exit 0; 
fi