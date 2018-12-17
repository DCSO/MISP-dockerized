FROM nginx:1.13.10-alpine
LABEL de.dcso.misp-proxy.version="0.0.1-alpha"
LABEL vendor="DCSO GmbH <www.dcso.de>"
LABEL de.dcso.misp-proxy.release-date="2018-01-02"
LABEL de.dcso.misp-proxy.is-production="false"
LABEL maintainer="Alexander Heidorn <alexander.heidorn@dcso.de>"

# Creating DH Params - https://weakdh.org/sysadmin.html
# Will be created via misp-robot.
#RUN openssl dhparam -out /etc/ssl/dhparams.pem 2048

# Copy the default config
COPY files/GLOBAL* files/SERVER* files/vars* /etc/nginx/conf.d/
# Add directory for maintenance File
RUN mkdir -p /var/www/maintenance
# Copy Maintenance config
COPY files/maintenance.html /var/www/maintenance/
# rename orig nginx.conf && place own nginx.conf
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.orig && ln -s /etc/nginx/conf.d/GLOBAL_nginx_common /etc/nginx/nginx.conf

# Add Healthcheck Config
HEALTHCHECK --interval=2m --timeout=15s --retries=3 CMD curl -f http://localhost/ || exit 1
