#!/bin/sh

echo "
Please use one of the following commands:
	General: 
	    make install		| Initial Command for: requirements, build-config, deploy
                make requirements	        | Check if server fullfill all requirements
                make build-config           | Build configuration
                make build-config REPOURL=<Custom Docker Registry URL> | Build configuration
                make deploy 		| Deploy Docker container
	    make upgrade 		| Upgrade MISP-dockerized
	    make update 		| Update MISP-dockerized same as make install
	    make delete 		| Delete all docker container and networks for MISP
	    make delete-volumes 	| Delete all docker container, networks and volumes 
	    make delete-images 		| Delete all docker container, networks and images 
	    make delete-all 		| Delete all docker container, networks, volumes and images 
	    make test	 		| Execute Test framework for CI
	Control Docker Instances\n\
	    make start-all		| Start all docker container
	    make stop-all		| Stop all docker container 
	    make restart-all	        | Restart all docker container 
	Configure: 
	    make change-ssl	        | Change ssl certificate and key
	    make change-smime	        | Change S/MIME certificate and key
	    make change-pgp		| Change PGP keys
	    make change-all 	        | Change SSL, S/MIME and PGP Keys 
	Maintenance: 
	    make enable-maintenance	| Enable maintenance mode at misp-proxy
	    make disable-maintenance	| Disable maintenance mode at misp-proxy
	Backup:
	    make backup-all 		| Backup all misp volumes via misp-robot
	    make backup-server		| Backup misp-server volumes via misp-robot
	    make backup-redis		| Backup misp-redis volumes via misp-robot
	    make backup-db		| Backup misp-db volumes via misp-robot
	    make backup-proxy		| Backup misp-proxy volumes via misp-robot
	    make backup-robot		| Backup misp-robot volumes via misp-robot
    Restore:
	    make restore-all		| Restore all via misp-robot
	    make restore-server		| Restore misp-server volumes via misp-robot
	    make restore-redis		| Restore misp-redis volumes via misp-robot
	    make restore-db		| Restore misp-db volumes via misp-robot
	    make restore-proxy		| Restore misp-proxy volumes via misp-robot
	    make restore-robot		| Restore misp-robot volumes via misp-robot
    Help:
	    make help	 		| Show help
"