
.PHONY: help \
		deploy \
		build-config \
		requirements \
		build-server build-proxy build-robot build-all \
		delete rebuild \
		backup-all backup-server backup-redis backup-mysql backup-proxy \
		security

# Shows Help and all Commands
help:
	@echo "Please use one of the following options:\n \
	\t make build-config	 	| build configuration\n \
	\t make deploy 				| deploy docker container\n \
	\t make configure 			| configure docker container via misp-robot\n \
	\t make rebuild 			| rebuild all docker container\n \
	\t make delete  			| delete all images, container and volumes\n \
	\t make build-server	 	| build misp-server\n \
	\t make build-proxy 		| build misp-proxy\n \
	\t make build-robot 		| build misp-robot\n \
	\t make build-all	 		| build all misp container\n \
	\t make security	 		| check docker security\n \
	\t make help	 			| show help\n"

# Check requirements
requirements:
	scripts/requirements.sh

# Start Docker environment
deploy: 
	scripts/startup.sh

# Configure Container
configure:
	docker exec -it misp-robot /bin/bash -c "/srv/configure_misp.sh"

# Build Configuration
build-config:
	scripts/build_config.sh

# Build Docker misp-server
build-server:
	container/build.sh server --no-cache

# Build Docker misp-proxy
build-proxy:
	container/build.sh proxy --no-cache

# Build Docker misp-robot
build-robot:
	container/build.sh robot --no-cache

# Build all misp docker-container
build-all:
	container/build.sh all  --no-cache

# delete all misp container, volumes and images
delete:
	bash scripts/stop_remove_hard.sh

# rebuild all docker container
rebuild:
	scripts/stop_and_rebuild.sh

# check with docker security check
security:
	scripts/check_docker_security.sh

# backup all services
backup-all:
	scripts/backup_restore.sh backup all
backup-server:
	scripts/backup_restore.sh backup server
backup-redis:
	scripts/backup_restore.sh backup redis
backup-mysql:
	scripts/backup_restore.sh backup mysql
backup-proxy:
	scripts/backup_restore.sh backup proxy

# restore service
restore:
	scripts/backup_restore.sh restore

