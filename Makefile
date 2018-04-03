
.PHONY: help \
		start requirements build-config deploy delete\
		security configure config-db config-server config-proxy \
		backup-all backup-server backup-redis backup-db backup-proxy backup-robot \
		build-server build-proxy build-robot build-all rebuild \

# Shows Help and all Commands
help:
	@echo "Please use one of the following options:\n \
	General: \n \
	\t make start			| Initial Command for: requirements, build-config, deploy\n \
	\t make requirements	 	| check if server fullfill all requirements\n \
	\t make build-config	 	| build configuration\n \
	\t make deploy 			| deploy docker container\n \
	\t make delete 			| delete all docker container, volumes and images for MISP\n \
	\t make delete-unused 		| delete all unused docker container, volumes and images \n \
	\t make security	 		| check docker security via misp-robot\n \
	Configure: \n \
	\t make configure 		| configure docker container via misp-robot\n \
	\t make config-db 		| configure misp-db via misp-robot\n \
	\t make config-server		| configure misp-server via misp-robot\n \
	\t make config-proxy 		| configure misp-proxy via misp-robot\n \
	Backup: \n \
	\t make backup-all 		| backup all misp volumes via misp-robot\n \
	\t make backup-server		| backup misp-server volumes via misp-robot\n \
	\t make backup-redis		| backup misp-redis volumes via misp-robot\n \
	\t make backup-db			| backup misp-db volumes via misp-robot\n \
	\t make backup-proxy		| backup misp-proxy volumes via misp-robot\n \
	\t make backup-robot		| backup misp-robot volumes via misp-robot\n \
	\t make restore			| restore volumes via misp-robot\n \
	\nFor testing or manul docker container only:\n \
	\t make build-all	 		| build all misp container\n \
	\t make build-server	 	| build misp-server\n \
	\t make build-proxy 		| build misp-proxy\n \
	\t make build-robot 		| build misp-robot\n \
	\t make rebuild 			| rebuild all docker container\n \
	\t make help	 		| show help\n"

# Start
start: requirements #build-config deploy
	@echo "##############################\n# MISP environment is ready.\n##############################"

####################	used as host
# Check requirements
requirements:
	scripts/requirements.sh

# Build Configuration
build-config:
	docker run --name misp-robot-init --rm -ti \
		-v ${PWD}/config:/srv/misp-dockerized/config \
		dcso/misp-robot bash -c "scripts/build_config.sh"

# Start Docker environment
deploy: 
	scripts/startup.sh

# delete all misp container, volumes and images
delete:
	scripts/delete_all_misp_from_host.sh

delete-unused:
	docker system prune

####################	used in misp-robot	####################

# check with docker security check
security:
	docker exec -it misp-robot /bin/bash -c "scripts/check_docker_security.sh"

# configure
configure:
	docker exec -it misp-robot /bin/bash -c "/srv/configure_misp.sh"
config-server:
	docker exec -it misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t server /etc/ansible/playbooks/robot-playbook/site.yml"
config-db:
	docker exec -it misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t database /etc/ansible/playbooks/robot-playbook/site.yml"
config-proxy:
	docker exec -it misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t proxy /etc/ansible/playbooks/robot-playbook/site.yml"

# backup all services
backup-all:
	docker exec -it misp-robot /bin/bash -c "scripts/backup_restore.sh backup all"
backup-server:
	docker exec -it misp-robot /bin/bash -c "scripts/backup_restore.sh backup server"
backup-redis:
	docker exec -it misp-robot /bin/bash -c "scripts/backup_restore.sh backup redis"
backup-db:
	docker exec -it misp-robot /bin/bash -c "scripts/backup_restore.sh backup mysql"
backup-proxy:
	docker exec -it misp-robot /bin/bash -c "scripts/backup_restore.sh backup proxy"
backup-robot:
	docker exec -it misp-robot /bin/bash -c "scripts/backup_restore.sh backup robot"

# restore service
restore:
	docker exec -it misp-robot /bin/bash -c "scripts/backup_restore.sh restore"

####################	used only for manuall deploying or debugging	#############

# Build all misp docker-container
build-all:
	container/build.sh all

# Build Docker misp-server
build-server:
	container/build.sh server

# Build Docker misp-proxy
build-proxy:
	container/build.sh proxy

# Build Docker misp-robot
build-robot:
	container/build.sh robot

# rebuild all docker container
rebuild:
	scripts/rebuild.sh
