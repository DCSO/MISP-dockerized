#!/bin/sh

docker run \
	    --name misp-robot-init \
		--rm \
	    	--network="host" \
	    	-v $PWD:/srv/MISP-dockerized \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		$(cat $PWD/config/config.env|grep DOCKER_REGISTRY|cut -d = -f 2)/misp-dockerized-robot:$(cat $PWD/config/config.env|grep ROBOT_CONTAINER_TAG|cut -d = -f 2) bash -c "docker-compose -f /srv/MISP-dockerized/docker-compose.yml -f /srv/MISP-dockerized/docker-compose.override.yml up -d "
	docker cp $PWD/config/ssl/. misp-proxy:/etc/nginx/ssl/