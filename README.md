MISP dockerized
====

# About
**MISP dockerized** is a project designed to provide an easy-to-use and easy-to-install 'out of the box' MISP instance that includes everything you need to run MISP with minimal host-side requirements. 

**MISP dockerized** uses MISP (Open Source Threat Intelligence Platform - https://github.com/MISP/MISP), which is maintend and developed by the MISP project team (https://www.misp-project.org/).



# Documentation
The documentation of MISP-dockerized is central published at the following address: https://dcso.github.io/MISP-dockerized-docs.

# Upgrade from Beta to 1.0.0
* Make an snapshot from your server
* `docker exec -ti misp-robot sh -c "apt update && apt install -y mysql-client"`
* `cd <PATH to MISP-dockerized repo>`
* `make backup-all`
* `make delete`
* `rm docker-compose.yml`
* git pull or git checkout origin/master -f
* `make install`
* wait ca. 90 seconds: `docker logs -f misp-server`
* `make -C current restore-db`
* `make -C current restore-server`
* `make -C current change-ssl`
* `docker exec -ti misp-server bash -c "rm /etc/apache2/ssl/SSL_create.pid.proxy"`
* `make -C current restart-all`





# License

This software is released under a BSD 3-Clause license.
Please have a look at the LICENSE file included in the repository.

Copyright (c) 2018, DCSO Deutsche Cyber-Sicherheitsorganisation GmbH
