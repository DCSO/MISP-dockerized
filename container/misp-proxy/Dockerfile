#FROM nginx:1.13.9
FROM ubuntu:16.04
#LABEL de.dcso.misp-proxy.version="0.0.1-beta"
LABEL vendor="DCSO GmbH <www.dcso.de>"
LABEL de.dcso.misp-proxy.release-date="2018-01-02"
LABEL de.dcso.misp-proxy.is-production="false"
LABEL maintainer="DCSO MISP <misp@dcso.de>"

# Install core components
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && apt-get autoremove -y && apt-get clean -y
RUN apt-get install -y software-properties-common
RUN apt-get install -y \ 
supervisor \
nano \
vim \
curl \
gcc \
make \
locales \
zip \
iputils-ping \
curl \
make \
openssl \
vim \
net-tools \
sudo

# Install NGINX
RUN apt-get install -y nginx

# Set locals
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# Creating DH Params - https://weakdh.org/sysadmin.html
# Will be created via misp-robot.
#RUN openssl dhparam -out /etc/ssl/dhparams.pem 2048

# Copy the default config
COPY files/GLOBAL* files/SERVER* files/vars* /etc/nginx/conf.d/
# Add directory for maintenance File
RUN mkdir /var/www/maintenance
# Copy Maintenance config
COPY files/maintenance.html /var/www/maintenance/
# Deactivate NGINX Default config && rename orig nginx.conf && place own nginx.conf
RUN rm -f /etc/nginx/sites-enabled/default && mv /etc/nginx/nginx.conf /etc/nginx/nginx.orig && ln -s /etc/nginx/conf.d/GLOBAL_nginx_common /etc/nginx/nginx.conf

# RUN mkdir /etc/ssl/private
RUN chmod -R 640 /etc/ssl/private

# Environment Variable for Proxy
ENV HTTP_PROXY=""
ENV NO_PROXY="0.0.0.0"

# Add Healthcheck Config
HEALTHCHECK --interval=2m --timeout=15s --retries=3 CMD curl -f http://localhost/ || exit 1

# Install core components
ENTRYPOINT ["nginx", "-g", "daemon off;"]
