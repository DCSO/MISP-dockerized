FROM ubuntu:16.04

#     Variables:
# for Labels:
ARG VENDOR="DCSO GmbH <www.dcso.de>"
ARG RELEASE_DATE
ARG IS_PRODUCTION="false"
ARG MAINTAINER="DCSO MISP <misp@dcso.de>"
ARG BUILD_DATE
ARG NAME
ARG GIT_REPO
ARG VCS_REF
ARG VERSION
#     END Variables

LABEL vendor=${VENDOR}
LABEL de.dcso.misp-server.version=${VERSION}
LABEL de.dcso.misp-server.release-date=${RELEASE_DATE}
LABEL de.dcso.misp-server.is-production=${IS_PRODUCTION}
LABEL maintainer=${MAINTAINER}
LABEL org.label-schema.build-date="${BUILD_DATE}" \
          org.label-schema.name="MISP-dockerized ${NAME}" \
          org.label-schema.description="This docker container is part of the DCSO MISP dockerized environment." \
          org.label-schema.vcs-ref="${VCS_REF}" \
          org.label-schema.vcs-url="${GIT_REPO}" \
          org.label-schema.vendor="${VENDOR}" \
          org.label-schema.version="${VERSION}" \
          org.label-schema.schema-version="1.0.0-rc1"

# Install core, additional and docker dependency components
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y; \
    apt-get install -y \ 
        software-properties-common \
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
        mariadb-client \
        python-mysqldb \
        python-dev \
        python-pip \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        python-setuptools \
        apt-transport-https \
        ca-certificates; \
    apt-get upgrade -y; \
    apt-get autoremove -y; \ 
    apt-get clean -y

# # Install additional dependencies
#   APT additional dependencies are installed on the first APT Run:
# RUN apt-get install -y \ 
# mariadb-client \
# python-mysqldb \
# python-dev \
# python-pip \
# libxml2-dev \
# libxslt1-dev \
# zlib1g-dev \
# python-setuptools \
# && apt-get autoremove -y && apt-get clean -y

# Install Docker
# https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce
#   APT Docker dependencies are installed on the first APT Run:
# RUN apt-get install -y \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     software-properties-common; \
#     apt-get autoremove -y; apt-get clean -y;

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ; \
    apt-key fingerprint 0EBFCD88; \
    add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" ;\
    apt-get update; apt-get install -y docker-ce; apt-get autoremove -y && apt-get clean -y

# change language
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# Update PIP
RUN pip install --upgrade pip; \
    pip3 install --upgrade pip

# Install docker-compose
RUN pip install docker-compose

# Setup Ansible
RUN add-apt-repository ppa:ansible/ansible; \
    apt-get update -y; \
    apt-get install ansible -y && apt-get autoremove -y && apt-get clean -y \
    mkdir /etc/ansible/playbooks
    
#CMD ["/sbin/tini", "-g", "--", "/srv/docker-entrypoint.sh"]

COPY files/hosts /etc/ansible/hosts
COPY files/robot-playbook /etc/ansible/playbooks/robot-playbook

# Download MISP DB Schema
RUN mkdir -p /srv/misp_db_scheme; \
    curl -o /srv/misp_db_scheme/v2.4.88_MYSQL.sql https://raw.githubusercontent.com/MISP/MISP/v2.4.88/INSTALL/MYSQL.sql; \
    curl -o /srv/misp_db_scheme/v2.4.89_MYSQL.sql https://raw.githubusercontent.com/MISP/MISP/v2.4.89/INSTALL/MYSQL.sql;

# Add scripts and make it executable
COPY files/scripts/* /srv/scripts/
RUN chmod +x /srv/scripts

# Setup Workdir
WORKDIR /srv

# Add Healthcheck Config
HEALTHCHECK NONE

# Environment Variable for Proxy
ENV HTTP_PROXY=""
ENV NO_PROXY="0.0.0.0"

# Environment Variable to check Version
ENV VERSION=${VERSION}