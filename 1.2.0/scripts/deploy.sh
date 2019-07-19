#!/bin/sh

docker run \
	    --name misp-robot-init \
		--rm \
	    	--network="host" \
	    	-v "$PWD":/srv/MISP-dockerized \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		"$(grep DOCKER_REGISTRY "$PWD"/config/config.env|cut -d = -f 2)"/misp-dockerized-robot:\
			"$(grep ROBOT_CONTAINER_TAG "$PWD"/config/config.env|cut -d = -f 2)" \
				bash -c "docker-compose -f /srv/MISP-dockerized/docker-compose.yml \
					-f /srv/MISP-dockerized/docker-compose.override.yml up -d "
# Copy SSL
[ -d "$PWD"/config/ssl ] && docker cp "$PWD"/config/ssl/. misp-proxy:/etc/nginx/ssl/
