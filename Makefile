.PHONY: help \
		start requirements build-config deploy delete change-ssl disable-maintenance enable-maintenance\
		security configure config-db config-server config-proxy \
		backup-all backup-server backup-redis backup-db backup-proxy backup-robot \
		build-server build-proxy build-robot build-all \

# Shows Help and all Commands
help:
	@echo "Please use one of the following options:\n \
	General: \n \
	       make install			| Initial Command for: requirements, build-config, deploy\n \
	       make requirements	 	| check if server fullfill all requirements\n \
	       make build-config	 	| build configuration\n \
	       make deploy 			| deploy docker container\n \
		make upgrade 			| upgrade MISP-dockerized\n \
		make update 			| update MISP-dockerized same as make install\n \
	       make delete 			| delete all docker container, volumes and images for MISP\n \
	       make delete-unused 		| delete all unused docker container, volumes and images \n \
	       make security	 		| check docker security via misp-robot\n \
	Control Docker Instances\n\
		make start-all			| start all docker container\n \
		make stop-all			| stop all docker container \n \
		make restart-all		| restart all docker container \n \
	Configure: \n \
	       make change-ssl			| change ssl cert\n \
	       make configure 			| configure docker container via misp-robot\n \
	       make config-db 			| configure misp-db via misp-robot\n \
	       make config-server		| configure misp-server via misp-robot\n \
	       make config-proxy 		| configure misp-proxy via misp-robot\n \
	Maintenance: \n \
	    	make enable-maintenance		| enable maintenance mode \n \
	    	make disable-maintenance	| disable maintenance mode \n \
	Backup: \n \
	       make backup-all 		| backup all misp volumes via misp-robot\n \
	       make backup-server		| backup misp-server volumes via misp-robot\n \
	       make backup-redis		| backup misp-redis volumes via misp-robot\n \
	       make backup-db			| backup misp-db volumes via misp-robot\n \
	       make backup-proxy		| backup misp-proxy volumes via misp-robot\n \
	       make backup-robot		| backup misp-robot volumes via misp-robot\n \
	       make restore			| restore volumes via misp-robot\n \
	Help: \n \
	       make help	 		| show help\n"

# Start
install: requirements build-config deploy configure
	@echo
	@echo " ###########	MISP environment is ready	###########"
	@echo "Please go to: $(shell cat .env|grep HOSTNAME|cut -d = -f 2)"
	@echo "Login credentials:"
	@echo "      Username: admin@admin.test"
	@echo "      Password: admin"
	@echo
	@echo "Do not forget to change your SSL certificate with:    make change-ssl"
	@echo " ##########################################################"
	@echo

####################	used as host	####################
# Check requirements
requirements:
	@echo " ###########	Checking Requirements	###########"
	@scripts/requirements.sh

# Build Configuration
build-config:
	@echo " ###########	Build Configuration	###########"
	@scripts/build_config.sh

# Start Docker environment
deploy: 
	@echo " ###########	Deploy Environment	###########"
	sed -i "s,myHOST_PATH,$(CURDIR),g" "./docker-compose.yml"
	docker run --name misp-robot-init --rm \
		-v $(CURDIR):/srv/MISP-dockerized \
    	-v $(CURDIR)/scripts:/srv/scripts:ro \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		$(shell cat $(CURDIR)/.env|grep DOCKER_REGISTRY|cut -d = -f 2)/misp-dockerized-robot:$(shell cat $(CURDIR)/.env|grep ROBOT_CONTAINER_TAG|cut -d = -f 2) bash -c "scripts/deploy_environment.sh /srv/MISP-dockerized/"

# delete all misp container, volumes and images
delete:
	scripts/delete_all_misp_from_host.sh

# delete all unused docker images on the host
delete-unused:
	docker system prune

# stop all misp docker container
stop-all:
	docker stop misp-server
	docker stop misp-proxy
	docker stop misp-postfix
	docker stop misp-robot

# start all misp docker container
start-all:
	docker start misp-server
	docker start misp-proxy
	docker start misp-postfix
	docker start misp-robot

# restart all misp docker container
restart-all: stop-all start-all

# upgrade to a new version
upgrade:
	@echo " ###########	Upgrade MISP-dockerized to a new version	###########"
	@scripts/upgrade.sh

# Update current MISP to all new functions in this Version without a new version
update: install



####################	used in misp-robot	####################
DOCKER_EXEC=docker exec
#DOCKER_EXEC= "docker run -it --rm "

# check with docker security check
security:
	@echo " ###########	Check Docker Security	###########	"
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/check_docker_security.sh"

# logging on whole service if syslog is deactivated
log:
	$(DOCKER_EXEC) misp-robot docker-compose -f /srv/MISP-dockerized/docker-compose.yml logs

log-f:
	$(DOCKER_EXEC) misp-robot docker-compose -f /srv/MISP-dockerized/docker-compose.yml logs -f

# configure
configure:
	@echo " ###########	Configure Environment	###########	"
	$(DOCKER_EXEC) misp-robot /bin/bash -c "/srv/scripts/configure_misp.sh"
config-server:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t server /etc/ansible/playbooks/robot-playbook/site.yml"
config-db:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t database /etc/ansible/playbooks/robot-playbook/site.yml"
config-proxy:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t proxy /etc/ansible/playbooks/robot-playbook/site.yml"
config-smime:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t smime /etc/ansible/playbooks/robot-playbook/site.yml"
config-pgp:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t pgp /etc/ansible/playbooks/robot-playbook/site.yml"

# maintainence
enable-maintenance:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t enable /etc/ansible/playbooks/robot-playbook/maintenance.yml"
disable-maintenance:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t disable /etc/ansible/playbooks/robot-playbook/maintenance.yml"

# reconfigure ssl
change-ssl: config-server config-proxy

# backup all services
backup-all:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh backup all"
backup-server:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh backup server"
backup-redis:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh backup redis"
backup-db:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh backup mysql"
backup-proxy:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh backup proxy"
backup-robot:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh backup robot"

# restore service
restore:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh restore"
