FROM nginx:1.13-alpine

#     Variables:
# for Labels:
ARG VENDOR="DCSO GmbH <www.dcso.de>"
ARG RELEASE_DATE
ARG IS_PRODUCTION="false"
ARG MAINTAINER="DCSO MISP <misp@dcso.de>"
ARG BUILD_DATE
ARG NAME=
ARG GIT_REPO
ARG VCS_REF
ARG VERSION
#     END Variables

#LABEL de.dcso.misp-server.version="0.0.1-alpha"
LABEL vendor=${VENDOR}
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

# Copy the default config
COPY files/GLOBAL* files/SERVER* files/vars* /etc/nginx/conf.d/
# Add directory for maintenance File
RUN mkdir -p /var/www/maintenance
# Copy Maintenance config
COPY files/maintenance.html /var/www/maintenance/
# rename orig nginx.conf && place own nginx.conf
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.orig \
    && ln -s /etc/nginx/conf.d/GLOBAL_nginx_common /etc/nginx/nginx.conf \
    && rm -f /etc/nginx/conf.d/default.conf

# Environment Variable for Proxy
ENV HTTP_PROXY=""
ENV NO_PROXY="0.0.0.0"
# Environment Variable to check Version
ENV VERSION=${VERSION}

# Add Healthcheck Config
HEALTHCHECK --interval=2m --timeout=15s --retries=3 CMD curl -f http://localhost/ || exit 1
