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
	       make requirements	 	| Check if server fullfill all requirements\n \
	       make deploy 			| Deploy Docker container\n \
		make upgrade 			| Upgrade MISP-dockerized\n \
		make update 			| Update MISP-dockerized same as make install\n \
	       make delete 			| Delete all docker container, volumes and images for MISP\n \
	       make delete-unused 		| Delete all unused docker container, volumes and images \n \
	       make security	 		| Check docker security via misp-robot\n \
		make test	 		| Test if MISP-environment is ready.\n \
		\n \
		make build-config REPOURL=<Custom Docker Registry URL>	 	| Build configuration\n \
		\n \
	\n Control Docker Instances\n\
		make start-all			| Start all docker container\n \
		make stop-all			| Stop all docker container \n \
		make restart-all		| Restart all docker container \n \
	\n Configure: \n \
	       make change-ssl			| Change ssl certificate and key\n \
		make change-smime		| Change S/MIME certificate and key\n \
		make change-pgp			| Change PGP keys\n \
		make change-all 		| Change SSL, S/MIME and PGP Keys \n \
	\n Maintenance: \n \
	    	make enable-maintenance		| Enable maintenance mode \n \
	    	make disable-maintenance	| Disable maintenance mode \n \
	\n Backup: \n \
	       make backup-all 		| Backup all misp volumes via misp-robot\n \
	       make backup-server		| Backup misp-server volumes via misp-robot\n \
	       make backup-redis		| Backup misp-redis volumes via misp-robot\n \
	       make backup-db			| Backup misp-db volumes via misp-robot\n \
	       make backup-proxy		| Backup misp-proxy volumes via misp-robot\n \
	       make backup-robot		| Backup misp-robot volumes via misp-robot\n \
	       \n \
		make restore-all		| Restore all via misp-robot\n \
		make restore-server		| Restore misp-server volumes via misp-robot\n \
	       make restore-redis		| Restore misp-redis volumes via misp-robot\n \
	       make restore-db			| Restore misp-db volumes via misp-robot\n \
	       make restore-proxy		| Restore misp-proxy volumes via misp-robot\n \
	       make restore-robot		| Restore misp-robot volumes via misp-robot\n \
	\n Help: \n \
	       make help	 		| Show help\n"

# Start
install: requirements build-config pull deploy
	@echo
	@echo " ###########	MISP environment is ready	###########"
	@echo "Please go to: $(shell cat config/config.env|grep HOSTNAME|cut -d = -f 2)"
	@echo "Login credentials:"
	@echo "      Username: admin@admin.test"
	@echo "      Password: admin"
	@echo
	@echo "Do not forget to change your SSL certificate with:    make change-ssl"
	@echo "Do not forget to change your S/MIME certificate with:    make change-smime"
	@echo "Do not forget to change your PGP certificate with:    make change-pgp'"
	@echo " ##########################################################"
	@echo

####################	used as host	####################
# Check requirements
requirements:
	@echo " ###########	Checking Requirements	###########"
	@scripts/requirements.sh
	@sleep 2

support:
	make -C ../ support

# Build Configuration
build-config:
	@echo " ###########	Build Configuration	###########"
	@scripts/build_config.sh $(REPOURL)
	@sleep 2

# Start Docker environment
pull:
	@echo " ###########	Pull Environment	###########"
	docker run \
	    --name misp-robot-init \
		--rm \
	    	--network="host" \
	    	-v $(CURDIR):/srv/MISP-dockerized \
    	-v $(CURDIR)/scripts:/srv/scripts:ro \
		-v ~/.docker:/root/.docker:ro \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		$(shell cat $(CURDIR)/config/config.env|grep DOCKER_REGISTRY|cut -d = -f 2)/misp-dockerized-robot:$(shell cat $(CURDIR)/config/config.env|grep ROBOT_CONTAINER_TAG|cut -d = -f 2) bash -c "docker-compose -f /srv/MISP-dockerized/docker-compose.yml -f /srv/MISP-dockerized/docker-compose.override.yml pull "
deploy: 
	@echo " ###########	Deploy Environment	###########"
	docker run \
	    --name misp-robot-init \
		--rm \
	    	--network="host" \
	    	-v $(CURDIR):/srv/MISP-dockerized \
    	-v $(CURDIR)/scripts:/srv/scripts:ro \
		-v ~/.docker:/root/.docker:ro \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		$(shell cat $(CURDIR)/config/config.env|grep DOCKER_REGISTRY|cut -d = -f 2)/misp-dockerized-robot:$(shell cat $(CURDIR)/config/config.env|grep ROBOT_CONTAINER_TAG|cut -d = -f 2) bash -c "docker-compose -f /srv/MISP-dockerized/docker-compose.yml -f /srv/MISP-dockerized/docker-compose.override.yml up -d "

# delete all misp container, volumes and images
delete: copy-ssl
	scripts/delete_all_misp_from_host.sh

# stop all misp docker container
stop-all:
	docker stop misp-server
	docker stop misp-proxy
	docker stop misp-modules
	docker stop misp-robot

# start all misp docker container
start-all:
	docker start misp-server
	docker start misp-proxy
	docker start misp-modules
	docker start misp-robot

# restart all misp docker container
restart-all: stop-all start-all

# upgrade to a new version
upgrade:
	@echo " ###########	Upgrade MISP-dockerized to a new version	###########"
	@cd ../
	@UPGRADE.sh

# Update current MISP to all new functions in this Version without a new version
update: install


test:
	@make -C ../.ci test
	@echo
	@echo "#############################################"
	@echo "For the report output: cat $(CURDIR)/.travis/reports/*.xml"
	@echo "#############################################"


####################	used in misp-robot	####################
DOCKER_EXEC=docker exec -ti
#DOCKER_EXEC= "docker run -it --rm "

# configure
configure:
	@echo " ###########	Configure Environment	###########	"
	make copy-smime
	make copy-pgp
	make config-ssl


change-ssl: config-ssl
config-ssl: copy-ssl
	docker restart misp-server
	docker restart misp-proxy

# x509 SSL Certificate
copy-ssl:
	-docker cp $(CURDIR)/config/ssl/cert.pem misp-proxy:/etc/nginx/ssl/
	-docker cp $(CURDIR)/config/ssl/key.pem misp-proxy:/etc/nginx/ssl/
	-docker cp misp-proxy:/etc/nginx/ssl/cert.pem $(CURDIR)/config/ssl/
	-docker cp misp-proxy:/etc/nginx/ssl/key.pem $(CURDIR)/config/ssl/

# S/MIME
change-smime: copy-smime
copy-smime:
	#$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t smime /etc/ansible/playbooks/robot-playbook/site.yml"
	docker cp $(CURDIR)/config/smime/. misp-server:/var/www/MISP/.smime

# GnuPGP
change-pgp: copy-pgp
copy-pgp:
	#$(DOCKER_EXEC) misp-robot /bin/bash -c "ansible-playbook -i 'localhost,' -c local -t pgp /etc/ansible/playbooks/robot-playbook/site.yml"
	docker cp $(CURDIR)/config/pgp/. misp-server:/var/www/MISP/.pgp

# maintainence
enable-maintenance:
	$(DOCKER_EXEC) misp-proxy /entrypoint_nginx.sh enable-maintenance
	docker restart misp-proxy
disable-maintenance:
	$(DOCKER_EXEC) misp-proxy /entrypoint_nginx.sh disable-maintenance
	docker restart misp-proxy

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
backup-ssl: copy-ssl

# restore service
restore-all:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh restore all"
restore-server:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh restore server"
restore-redis:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh restore redis"
restore-db:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh restore mysql"
restore-proxy:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh restore proxy"
restore-robot:
	$(DOCKER_EXEC) misp-robot /bin/bash -c "scripts/backup_restore.sh restore robot"

