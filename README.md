MISP dockerized
====

# About
**MISP dockerized** is a project designed to provide an easy-to-use and easy-to-install 'out of the box' MISP instance that includes everything you need to run MISP with minimal host-side requirements. 

**MISP dockerized** uses MISP (Open Source Threat Intelligence Platform - https://github.com/MISP/MISP), which is maintend and developed by the MISP project team (https://www.misp-project.org/)

**THIS PROJECT IS IN BETA PHASE**

### Project Information
<table>
<tr>
  <td>Travis Master</td>
  <td><a href="https://travis-ci.org/DCSO/MISP-dockerized"><img src="https://travis-ci.org/DCSO/MISP-dockerized.svg?branch=master" /></a></td>
</tr>
</table>

### Available MISP-Versions
| Version | Status | Notes |
| ---- | --- | --- | 
| 2.4.88 | deprecated | |
| 2.4.89 | deprecated | |
| 2.4.90 | deprecated | |
| 2.4.91 | deprecated | |
| 2.4.92 | deprecated | |
| 2.4.93 | current ||
| 2.4.94 | current ||

See https://github.com/DCSO/MISP-dockerized-server for more details like available and supported tags

### Docker Container Information

| Name         | Travis        | Commit | Docker Size & Layers | Latest Docker Version        | 
| ------------ | ------------- | -------------------- | --------------------- | ------------- | 
| misp-dockerized-proxy   | [![][1]][2]   | [![][6]][7]          | [![][4]][7]           | [![][5]][7]   | 
| misp-dockerized-server  | [![][8]][9]   | [![][13]][14]        | [![][11]][14]         | [![][12]][14] | 
| misp-dockerized-robot   | [![][15]][16] | [![][20]][21]        | [![][18]][21]         | [![][19]][21] | 
| misp-dockerized-postfix | [![][22]][23] | [![][27]][28]        | [![][25]][28]         | [![][26]][28] | 


[1]: https://travis-ci.org/DCSO/MISP-dockerized-proxy.svg?branch=master
[2]: https://travis-ci.org/DCSO/MISP-dockerized-proxy
[4]: https://images.microbadger.com/badges/image/dcso/misp-dockerized-proxy.svg
[5]: https://images.microbadger.com/badges/version/dcso/misp-dockerized-proxy.svg
[6]: https://images.microbadger.com/badges/commit/dcso/misp-dockerized-proxy.svg
[7]: https://microbadger.com/images/dcso/misp-dockerized-proxy

[8]: https://travis-ci.org/DCSO/MISP-dockerized-server.svg?branch=master
[9]: https://travis-ci.org/DCSO/MISP-dockerized-server
[11]: https://images.microbadger.com/badges/image/dcso/misp-dockerized-server.svg
[12]: https://images.microbadger.com/badges/version/dcso/misp-dockerized-server.svg
[13]: https://images.microbadger.com/badges/commit/dcso/misp-dockerized-server.svg
[14]: https://microbadger.com/images/dcso/misp-dockerized-server

[15]: https://travis-ci.org/DCSO/MISP-dockerized-robot.svg?branch=master
[16]: https://travis-ci.org/DCSO/MISP-dockerized-robot
[18]: https://images.microbadger.com/badges/image/dcso/misp-dockerized-robot.svg
[19]: https://images.microbadger.com/badges/version/dcso/misp-dockerized-robot.svg
[20]: https://images.microbadger.com/badges/commit/dcso/misp-dockerized-robot.svg
[21]: https://microbadger.com/images/dcso/misp-dockerized-robot

[22]: https://travis-ci.org/DCSO/MISP-dockerized-postfix.svg?branch=master
[23]: https://travis-ci.org/DCSO/MISP-dockerized-postfix
[25]: https://images.microbadger.com/badges/image/dcso/misp-dockerized-postfix.svg
[26]: https://images.microbadger.com/badges/version/dcso/misp-dockerized-postfix.svg
[27]: https://images.microbadger.com/badges/commit/dcso/misp-dockerized-postfix.svg
[28]: https://microbadger.com/images/dcso/misp-dockerized-postfix

# Installation
## Software Prerequsites
For the Installation of MISP dockerized you need at least:

| Component | minimum Version                  |
| --------- | -------------------------------- |
| Docker    | 17.03.0-ce                       |
| Git       | newest Version from Distribution |


## Firewall Prerequsites
For the Installation the followed Connections need to available:

| URL                  | Direction    | Protocol | Destination Port |
| -------------------- | ------------ | -------- | ---------------- |
| *.docker.io | outgoing | TCP | 443      |
| *.docker.com | outgoing |  TCP | 443      |
| github.com*          | outgoing     | TCP      | 443              |
| misp.dcso.de       | outgoing     | TCP      | 443              |

### Why docker.io and docker.com:
This contains all required docker container:

| Container   | based on         | purpose                        |
| ----------- | ---------------- | ------------------------------ |
| misp-proxy  | alpine           | reverse proxy                  |
| misp-server | ubuntu           | MISP application server, redis server and DB server        |
| misp-robot  | ubuntu           | deploy & configuration manager |

### Why github.com
This contains:
- scripts
- tools


## The 4 Step Installation Guide
### 1. Clone Repository
After cloning the repository change the branch to the required, for example:
```
$> git clone https://github.com/DCSO/MISP-dockerized.git
```

### 2. Configure TLS Certificates and Diffie-Hellmann File (optional)
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

### 3. Start Docker Environment
To start the deployment and build the configuration files and configure the whole environment, simply enter:
```
$> make start
```
We decided, that build config and deploy environment can be done in one step.

#### 3.1. [OPTIONAL] look if all required components are installed
**MISP dockerized** comes with a requirements script that checks if all components are installed, is the user part of the docker group and has the user the right permission on the github repository folder. Simply start:   
```
$> make requirements
```

#### 3.2 [OPTIONAL] Manual build config 
If you want to do it manual: **MISP dockerized** comes with a build script that creates all required config files. Simply start:   
```
$> make build-config
```
The build script download our DCSO/misp-robot and start him with the build script. Therefore you can't find the script directly in the github repository.

#### 3.3 [OPTIONAL] Manual deploy environment
To start the deployment process, simply enter:
```
$> make deploy
```

#### 3.4 [OPTIONAL] Configure the Instance
After deployment, you now have a simple basic MISP installation without any further configuration. To configure the instance with all specified parameters, use the following command:
```
$> make configure
```
After these step, you now should have a configured running MISP Instance!

### 4. Login in your new MISP Environment

**`Gratulation! Your MISP Environment is deployed!`**

Now you can setup and configure your MISP Environment as normal.
If you need Help look here: `https://www.circl.lu/doc/misp/`
Special for Quick Start in MISP: `https://www.circl.lu/doc/misp/quick-start/`


## Backup and Recovery
### Backup
To back up your instance, **MISP dockerized** comes with a backup and restore script that will do the job for you. To create a backup start:
```bash
$> make backup-[service] for example: make backup-all
```
`[service]` is the service you want to create a backup. you can chose between `redis|mysql|server|proxy|all`

### Restore
Works similar to the backup process. Just run the backup and restore script
```bash
$> make restore
```


# Help
### Make Docker Autostart at Startup
```
$ systemctl enable docker.service
```
### Delete the Docker Instance
To delete everything e.g. to start from scratch you can use this:
```
&> make delete
```
This delete the MISP images, network, containers and volumes.

**Warning**
`make delete` delete all volumes, leading to a loss of all your data. Make sure you have saved everything before you run it.


### Cannot download Docker images behind a proxy

First, create a systemd drop-in directory for the docker service:
```bash
$> mkdir /etc/systemd/system/docker.service.d
```

Now create a file called /etc/systemd/system/docker.service.d/http-proxy.conf that adds the HTTP_PROXY environment variable:
```bash
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:80/"
```
If you have internal Docker registries that you need to contact without proxying you can specify them via the NO_PROXY environment variable:
```bash
Environment="HTTP_PROXY=http://proxy.example.com:80/"
Environment="NO_PROXY=localhost,127.0.0.0/8,docker-registry.somecorporation.com"
```
Flush changes:
```bash
$> sudo systemctl daemon-reload
```
Verify that the configuration has been loaded:
```bash
$> sudo systemctl show --property Environment docker
Environment=HTTP_PROXY=http://proxy.example.com:80/
```
Restart Docker:
```bash
$> sudo systemctl restart docker
```



### Logging
If was possible, all logfiles are forwarded to docker log mechanism. Therefore you can do:
`docker logs -f misp-server` or any other container name.

### Rebuild from Backup
If you want to start from scratch or reinitialse your MISP instance, make sure you have delete everything. Clone the repository and start the container deployment with `make start`. After that restore all your volumes as described at `Backup and Recovery`.

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
docker system prune -a
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
* MISP-Modules
* Wiki
* FAQ's

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
