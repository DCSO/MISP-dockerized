#FROM debian:buster
FROM ubuntu:16.04
#LABEL de.dcso.misp-robot.version="0.0.1-alpha"
LABEL vendor="DCSO GmbH <www.dcso.de>"
LABEL de.dcso.misp-robot.release-date="2018-01-02"
LABEL de.dcso.misp-robot.is-production="false"
LABEL maintainer="DCSO MISP <misp@dcso.de>"

# Install core components
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && apt-get autoremove -y && apt-get clean -y
RUN apt-get install -y software-properties-common && apt-get autoremove -y && apt-get clean -y
RUN apt-get install -y \ 
#supervisor \
nano \
vim \
curl \
gcc \
make \
python \
python-pip \
python3 \
python3-pip \
locales \
zip \
iputils-ping \
git \
openssl \
net-tools \
sudo \
wget \
&& apt-get autoremove -y && apt-get clean -y

# Install additional dependencies
RUN apt-get install -y \ 
mariadb-client \
python-mysqldb \
python-dev \
python-pip \
libxml2-dev \
libxslt1-dev \
zlib1g-dev \
python-setuptools \
&& apt-get autoremove -y && apt-get clean -y

# Install Docker
# https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce
RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    && apt-get autoremove -y && apt-get clean -y

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
RUN apt-get update; apt-get install -y docker-ce; apt-get autoremove -y && apt-get clean -y

# change language
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# Update PIP
RUN pip install --upgrade pip
RUN pip3 install --upgrade pip

# Install docker-compose
RUN pip install docker-compose

# Setup Ansible
RUN add-apt-repository ppa:ansible/ansible
RUN apt-get update -y
RUN apt-get install ansible -y && apt-get autoremove -y && apt-get clean -y

RUN mkdir /etc/ansible/playbooks
#CMD ["/sbin/tini", "-g", "--", "/srv/docker-entrypoint.sh"]

COPY files/hosts /etc/ansible/hosts
COPY files/robot-playbook /etc/ansible/playbooks/robot-playbook
COPY files/configure_misp.sh /srv/configure_misp.sh
RUN chmod +x /srv/configure_misp.sh

# Download MISP DB Schema
RUN curl https://raw.githubusercontent.com/MISP/MISP/v2.4.88/INSTALL/MYSQL.sql -o /srv/misp_db_scheme/v2.4.88_MYSQL.sql; \
    curl https://raw.githubusercontent.com/MISP/MISP/v2.4.89/INSTALL/MYSQL.sql -o /srv/misp_db_scheme/v2.4.89_MYSQL.sql; \

# Add scripts
COPY files/scripts/* /srv/scripts/

# Setup Workdir
WORKDIR /srv

# Add Healthcheck Config
HEALTHCHECK NONE

# Environment Variable for Proxy
ENV HTTP_PROXY=""
ENV NO_PROXY="0.0.0.0"