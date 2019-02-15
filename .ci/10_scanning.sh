#!/bin/sh



export CI_CONTAINER_NAME: misp-dockerized-server
export CI_APPLICATION_REPOSITORY: $INTERNAL_REGISTRY_HOST/$CI_CONTAINER_NAME
export CI_APPLICATION_TAG: latest-dev

echo "$INTERNAL_REGISTRY_PW"| docker login -u "$INTERNAL_REGISTRY_USER" "$INTERNAL_REGISTRY_HOST" --password-stdin
docker run -d --name db arminc/clair-db:latest
docker run -p 6060:6060 --link db:postgres -d --name clair --restart on-failure arminc/clair-local-scan:v2.0.1
docker ps
apk add -U wget ca-certificates
docker pull ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG}
wget https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
mv clair-scanner_linux_amd64 clair-scanner
chmod +x clair-scanner
touch clair-whitelist.yml
#- while( ! wget -q -O /dev/null http://localhost:6060/v1/namespaces ) ; do sleep 1 ; done
#- retries=0
docker ps -a
echo "Waiting for clair daemon to start"
bash -c 'while( ! wget -T 10 -q -O /dev/null http://localhost:6060/v1/namespaces ) ; do sleep 1 ; echo -n "." ; if [ $retries -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; retries=$(($retries+1)) ; done'
bash -c ''./clair-scanner -c http://localhost:6060 --ip $(hostname -i) -r gl-container-scanning-report.json -l clair.log -w clair-whitelist.yml ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG} || true'

