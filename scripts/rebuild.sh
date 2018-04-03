#/bin/bash
echo '### stop and remove containers'
docker-compose rm -f -s
container/build.sh all
scripts/startup.sh

