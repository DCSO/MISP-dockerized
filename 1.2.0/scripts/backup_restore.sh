#!/bin/sh
set -eu
set -xv

if [ "$(docker ps -qf name=\"misp-robot\")" ];then
  echo "I try to start backup_restore script from current running misp-robot"
else
  echo "No misp-robot is identified, I start a temporary misp-robot"
	
  ROOT_DIR="$PWD/.."
  DOCKER_REGISTRY="$(grep DOCKER_REGISTRY "$PWD"/config/config.env|cut -d = -f 2)"
  ROBOT_CONTAINER_TAG="$(grep ROBOT_CONTAINER_TAG "$PWD"/config/config.env|cut -d = -f 2)"
  
  echo " ###########	Pull Image	###########"
	docker run \
	    --name misp-robot-backup-restore -ti --rm --network="host" \
	    -v "$ROOT_DIR":/srv/MISP-dockerized \
      -v ~/.docker:/root/.docker:ro \
		  -v /var/run/docker.sock:/var/run/docker.sock:ro \
		  "$DOCKER_REGISTRY"/misp-dockerized-robot:"$ROBOT_CONTAINER_TAG" sh -c "docker-compose -f /srv/MISP-dockerized/current/docker-compose.yml -f /srv/MISP-dockerized/current/docker-compose.override.yml pull misp-robot"
	
  echo " ###########	Start Backup Script	###########"
	docker run \
	    --name misp-robot-backup-restore -ti --rm --network="host" \
      -v "$ROOT_DIR":/srv/MISP-dockerized \
      -v ~/.docker:/root/.docker:ro \
		  -v /var/run/docker.sock:/var/run/docker.sock:ro \
      "$DOCKER_REGISTRY"/misp-dockerized-robot:"$ROBOT_CONTAINER_TAG" sh -c "docker-compose -f /srv/MISP-dockerized/current/docker-compose.yml -f /srv/MISP-dockerized/current/docker-compose.override.yml up -d misp-robot"
fi

# Start script

[ "${1-}" = "restore" ] && make install
sleep 2
echo "Start backup_restore script..."
docker exec -ti misp-robot sh -c "/srv/scripts/backup_restore.sh $*"
