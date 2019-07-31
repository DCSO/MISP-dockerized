#!/bin/sh
DOCKER_REGISTRY="$(grep DOCKER_REGISTRY "$PWD"/config/config.env|cut -d = -f 2)"
ROBOT_CONTAINER_TAG="$(grep ROBOT_CONTAINER_TAG "$PWD"/config/config.env|cut -d = -f 2)"

# shellcheck disable=SC2086
docker run \
	    --name misp-robot-init --rm --network="host" \
		-v "$PWD":/srv/MISP-dockerized \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		"$DOCKER_REGISTRY"/misp-dockerized-robot:$ROBOT_CONTAINER_TAG \
				bash -c "docker-compose -f /srv/MISP-dockerized/docker-compose.yml \
					-f /srv/MISP-dockerized/docker-compose.override.yml up -d "
# Copy SSL
[ -d "$PWD"/config/ssl ] && docker cp "$PWD"/config/ssl/. misp-proxy:/etc/nginx/ssl/
