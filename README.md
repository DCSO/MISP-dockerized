MISP dockerized
====
# About
**MISP dockerized** is a project designed to provide an easy-to-use and easy-to-install 'out of the box' MISP instance that includes everything you need to run MISP with minimal host-side requirements. 

**MISP dockerized** uses MISP (Open Source Threat Intelligence Platform - https://github.com/MISP/MISP), which is maintend and developed by the MISP project team (https://www.misp-project.org/)

**THIS PROJECT IS IN BETA PHASE**

# Installation
## Software Prerequsites
For the Installation of MISP dockerized you need at least:

| Component |  minimum Version   |
|----|-----|
| Docker   | 17.03.0-ce |
| Git   | newest Version from Distribution |


## Firewall Prerequsites
For the Installation the followed Connections need to available:

|URL|Direction|Protocol|Destination Port|
|---|---|---|---|
| hub.docker.com|outgoing|TCP|443|
| github.com*|outgoing|TCP|443|

### Why hub.docker.com:
This contains all required docker container:

|Container|based on|purpose|
|---|---|---|
|misp-redis|official redis|scheduled tasks|
|misp-db|official mariadb|database to save MISP settings|
|misp-proxy|1.13-alpine|reverse proxy|
|misp-server|ubuntu:16.04|MISP application server|
|misp-robot|ubuntu:16.04|deploy & configuration manager|

### Why github.com
This contains:
- scripts
- tools


## The 5 Step Installation Guide
### 1. Clone Repository
After cloning the repository change the branch to the required, for example:
```
$> git clone https://github.com/DCSO/MISP-dockerized.git && git checkout tags/2.4.88-beta.3
```

### 2. look if all required components are installed
**MISP dockerized** comes with a requirements script that checks if all components are installed, is the user part of the docker group and has the user the right permission on the github repository folder. Simply start:   
```
$> make requirements
```

### 3. Configure TLS Certificates and Diffie-Hellmann File (optional)
Before you start the container, you have to setup the TLS certificates and the Diffie-Hellman file.  
Please make sure that the **certificate** and **key** are in PEM-Format - recognizable in the first line:
> "-----BEGIN CERTIFICATE-----"  
or  
"-----BEGIN RSA PRIVATE KEY-----"  

when opening it in an editor like 'vim' or 'nano'  

If all prerequsites are fulfilled, you can deploy them as follows:
* Copy the Certificate **Key** File to `./config/ssl/key.pem` 
* Copy the Certificate **Chain** file to `./config/ssl/cert.pem`
* (**OPTIONAL**) During installation Diffie-Hellman Params will be freshly build, but if you still want to create them yourself, use the following command <sup>[1](#weakdh)</sup> or copy your existing one to `./config/ssl/dhparams.pem`

### 4. Start Docker Environment
To start the deployment and build the configuration files and configure the whole environment, simply enter:
```
$> make start
```
We decided, that build config and deploy environment can be done in one step.

#### 4.1 [OPTIONAL] Manual build config 
If you want to do it manual: **MISP dockerized** comes with a build script that creates all required config files. Simply start:   
```
$> make build-config
```
The build script download our DCSO/misp-robot and start him with the build script. Therefore you can't find the script directly in the github repository.

#### 4.2 [OPTIONAL] Manual deploy environment
To start the deployment process, simply enter:
```
$> make deploy
```

#### 4.3 [OPTIONAL] Configure the Instance
After deployment, you now have a simple basic MISP installation without any further configuration. To configure the instance with all specified parameters, use the following command:
```
$> make configure
```
After these step, you now should have a configured running MISP Instance!

### 5. Login in your new MISP Environment

**`Gratulation! Your MISP Environment is deployed!`**

Now you can setup and configure your MISP Environment as normal.
If you need Help look here: `https://www.circl.lu/doc/misp/`
Special for Quick Start in MISP: `https://www.circl.lu/doc/misp/quick-start/`


## Backup and Recovery
### Backup
To back up your instance, **MISP dockerized** comes with a backup and restore script that will do the job for you. To create a backup start:
```
$> ./scripts/backup_restore backup [service]
or 
$> make backup-[service] for example: make backup-all
```
`[service]` is the service you want to create a backup. you can chose between `redis|mysql|server|proxy|all`

### Restore
Works similar to the backup process. Just run the backup and restore script
```
$> ./scripts/backup_restore restore
or
$> make restore
```


## Help
### Make Docker Autostart at Startup
```
$ systemctl enable docker.service
```
### Rebuild or Delete the Repository
If you want to rebuild all containers e.g. if you change the docker-compose file, you can do this with `make`
```
&> make rebuild
```

To delete everything e.g. to start from scratch you can use this:
```
&> make delete
```

**Warning**
`make delete` delete all volumes, leading to a loss of all your data. Make sure you have saved everything before you run it.

### Rebuild from Backup
If you want to start from scratch or reinitialse your MISP instance, make sure you have delete everything. Clone the repository and start the container deployment with `make install`. After that restore all your volumes as described at `Backup and Recovery` and restart your container with
```
$> docker-compose restart misp-server misp-redis misp-db misp-proxy
```

### Access the Container
To access the container e.g. to change MISP config.php or proxy config, you can use:
```
docker exec -it dcso/[container] bash
```
Container variants: `misp-robot` `misp-server` `misp-proxy` (for the ubuntu version only)

For the misp-proxy if you have alpine version:
```
docker exec -it dcso/misp-proxy sh
```


### Usefull Commands
To Delete all local Images:
```
docker rmi $(docker images -q)
```

To delete only all non-tagged (dangling) Images:
```
docker rmi $(docker images -f "dangling=true" -q)
```

List Logs
```
docker logs -f misp-server
```

# What's missing
Currently the following things are not yet implemented but are planned
* GnuPG Support
* Postfix
* MISP-Modules

# Additional Informations
## MariaDB and Docker
* https://mariadb.com/kb/en/library/installing-and-using-mariadb-via-docker/
* https://hub.docker.com/r/_/mariadb/
## MISP
* https://github.com/MISP/MISP
* https://www.misp-project.org/

# License

This software is released under a BSD 3-Clause license.
Please have a look at the LICENSE file included in the repository.

Copyright (c) 2018, DCSO Deutsche Cyber-Sicherheitsorganisation GmbH
