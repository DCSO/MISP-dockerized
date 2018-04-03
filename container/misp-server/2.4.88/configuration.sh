# 
# Container Name
CONTAINER_NAME="misp-server"
# HTTPS GIT Repo URL:
GIT_REPO=https://github.com/DCSO/MISP-dockerized
# MISP TAG to build:
MISP_TAG=2.4.88
VERSION="$MISP_TAG-ubuntu"
# MISP Dependencies:
python_cybox_TAG=v2.1.0.12
python_stix_TAG=v1.1.1.4
mixbox_TAG=v1.0.2
cake_resque_TAG=4.1.2