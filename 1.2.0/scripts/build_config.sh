#!/bin/bash
#description     :This script build the configuration for the MISP Container and their content.
#==============================================================================
STARTMSG="[build_config.sh]"
set -eu

# Available Parameters from outside:
  # export CI=true
  [ "${CI-}" = true ] && AUTOMATE_BUILD=true # check if this is an automate build not ask any questions
  # export DEV=true
  [ "${DEV-}" = true ] && DEV_MODE=true
  # export DOCKER_REGISTRY=custom.url
  PARAMETER_DOCKER_REGISTRY="${1-}"


## GLOBAL Variables
  # Full Path <version>/scripts
  SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
  # Full Path in <version>
  MISP_dockerized_repo="${SCRIPTPATH%/*}"
  # Full Path in the Git Repository
  MISP_dockerized_repo="${MISP_dockerized_repo%/*}"
  # MISP-dockerized Configuration File
  CONFIG_FILE="${MISP_dockerized_repo}/config/config.env"
  # MISP-dockerized functions.sh file
  FUNCTIONS_FILE="${MISP_dockerized_repo}/current/scripts/functions.sh"
  # Docker-Compose Override File
  DOCKER_COMPOSE_OVERRIDE="${MISP_dockerized_repo}/current/docker-compose.override.yml"
  # Docker-Compose File
    # shellcheck disable=SC2034
  DOCKER_COMPOSE_FILE="${MISP_dockerized_repo}/current/docker-compose.yml"
  # Backup Folder Path
    # shellcheck disable=SC2034
  BACKUP_PATH="${MISP_dockerized_repo}/backup"

#################################################
##  import functions
#################################################
  # Import existing configuration
  echo -en "\e[1;32m$STARTMSG Check and import existing configuration file ...\e[0m"
  # shellcheck disable=SC1090
  [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
  echo "done"
  # Import functions file
  echo -en "\e[1;32m$STARTMSG Check and import global functions.sh file ...\e[0m" 
  # shellcheck disable=SC1090
  [ -f "$FUNCTIONS_FILE" ] && source "$FUNCTIONS_FILE" 
  echo "done"

######################################################################

# Function to set default values
func_check_if_vars_exists() {
  info_same_line "Check if all vars exists..."
  #
  # Default Variables for the config
  #
  # Docker Registry
  [ -z "${DOCKER_REGISTRY+x}" ] && DOCKER_REGISTRY="dcso" #&& QUERY_DOCKER_REGISTRY="yes" 
  # Docker Network
  [ -z "${NETWORK_CONTAINER_ADDRESS_RANGE+x}" ] && NETWORK_CONTAINER_ADDRESS_RANGE="192.168.47.0/28" && QUERY_NETWORK="yes" 
  [ -z "${NETWORK_BRIDGE_NAME+x}" ]    && NETWORK_BRIDGE_NAME="mispbr0" && QUERY_NETWORK="yes"
  [ -z "${NETWORK_BINDING_IPv4+x}" ]    && NETWORK_BINDING_IPv4="0.0.0.0" && QUERY_NETWORK="yes"
  
  # DEPRECATED: System Proxy for Container
  [ -n "${QUESTION_USE_PROXY+x}" ] && CONTAINER_SYSTEM_QUESTION_USE_PROXY="$QUESTION_USE_PROXY"
  [ -n "${HTTP_PROXY+x}" ]         && CONTAINER_SYSTEM_HTTP_PROXY="$HTTP_PROXY"
  [ -n "${HTTPS_PROXY+x}" ]        && CONTAINER_SYSTEM_HTTPS_PROXY="$HTTPS_PROXY"
  [ -n "${NO_PROXY+x}" ]           && CONTAINER_SYSTEM_NO_PROXY="$NO_PROXY"
  # END DEPRECATED
  # System Proxy for Container
  [ -z "${CONTAINER_SYSTEM_QUESTION_USE_PROXY+x}" ] && CONTAINER_SYSTEM_QUESTION_USE_PROXY="no" && QUERY_PROXY="yes"
  [ -z "${CONTAINER_SYSTEM_HTTP_PROXY+x}" ]         && CONTAINER_SYSTEM_HTTP_PROXY="" && QUERY_PROXY="yes"
  [ -z "${CONTAINER_SYSTEM_HTTPS_PROXY+x}" ]        && CONTAINER_SYSTEM_HTTPS_PROXY="" && QUERY_PROXY="yes"
  [ -z "${CONTAINER_SYSTEM_NO_PROXY+x}" ]           && CONTAINER_SYSTEM_NO_PROXY="0.0.0.0" && QUERY_PROXY="yes"
  
  # DEPRECATED: DB
  [ -n "${QUESTION_OWN_DB+x}" ]      && DB_QUESTION_OWN_DB="$QUESTION_OWN_DB"
  [ -n "${MYSQL_HOST+x}" ]           && DB_HOST="$MYSQL_HOST"
  [ -n "${MYSQL_PORT+x}" ]           && DB_PORT="$MYSQL_PORT"
  [ -n "${MYSQL_DATABASE+x}" ]       && DB_DATABASE="$MYSQL_DATABASE"
  [ -n "${MYSQL_USER+x}" ]           && DB_USER="$MYSQL_USER"
  [ -n "${MYSQL_PASSWORD+x}" ]       && DB_PASSWORD="$MYSQL_PASSWORD"
  [ -n "${MYSQL_ROOT_PASSWORD+x}" ]  && DB_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD"
  # END DEPRECATED
  # DB
  [ -z "${DB_QUESTION_OWN_DB+x}" ] && DB_QUESTION_OWN_DB="yes" && QUERY_DB="yes"
  [ -z "${DB_HOST+x}" ]            && DB_HOST="misp-db" && QUERY_DB="yes"
  [ -z "${DB_PORT+x}" ]            && DB_PORT="3306" && QUERY_DB="yes"
  [ -z "${DB_DATABASE+x}" ]        && DB_DATABASE="misp" && QUERY_DB="yes"
  [ -z "${DB_USER+x}" ]            && DB_USER="misp" && QUERY_DB="yes"
  [ -z "${DB_PASSWORD+x}" ]        && DB_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" && QUERY_DB="yes"
  [ -z "${DB_ROOT_PASSWORD+x}" ]   && DB_ROOT_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" && QUERY_DB="yes"
  
  # DEPRECATED MISP
  # shellcheck disable=SC2154
  [ -n "${myHOSTNAME+x}" ]         && MISP_FQDN="$myHOSTNAME"
  [ -n "${MISP_URL+x}" ]           && MISP_BASEURL="$MISP_URL"
  # shellcheck disable=SC2154
  [ -n "${MISP_prefix+x}" ]        && MISP_PREFIX="$MISP_prefix"
    # shellcheck disable=SC2154
  [ -n "${MISP_encoding+x}" ]      && MISP_ENCODING="$MISP_encoding"
  [ -n "${ADD_ANALYZE_COLUMN+x}" ] && MISP_ADD_EVENT_ANALYZE_COLUMN="$ADD_ANALYZE_COLUMN"
  # END DEPRECATED
  # MISP
  [ -z "${MISP_FQDN+x}" ]                     && MISP_FQDN="$(hostname -f)" && QUERY_myHOSTNAME="yes"
  [ -z "${MISP_BASEURL+x}" ]                  && QUERY_myHOSTNAME="yes" # It will be defined in myHOSTNAME MISP_BASEURL="https://${MISP_FQDN}"
  # if [ -z ${var+x} ]; then echo "var is unset"; else echo "var is set to '$var'"; fi
  [ -z "${MISP_PREFIX+x}" ]                   && MISP_PREFIX="" && QUERY_MISP="yes"
  [ -z "${MISP_ENCODING+x}" ]                 && MISP_ENCODING="utf8" && QUERY_MISP="yes"
  [ -z "${MISP_SALT+x}" ]                     && MISP_SALT="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 50)" && QUERY_MISP="yes"
  [ -z "${MISP_ADD_EVENT_ANALYZE_COLUMN+x}" ] && MISP_ADD_EVENT_ANALYZE_COLUMN="no" && QUERY_MISP="yes"
  [ -z "${MISP_HTTPS_PORT:+x}" ]              && MISP_HTTPS_PORT="443" && QUERY_MISP="yes"
  
  # MISP Container
  [ -z "${MISP_QUESTION_USE_NIGHTLY_BUILD:+x}" ] && MISP_QUESTION_USE_NIGHTLY_BUILD="no" && QUERY_LATEST_MISP_SERVER="yes"
  [ -z "${MISP_NIGHTLY_TAG:+x}" ] && MISP_NIGHTLY_TAG="2.4.nightly-debian"

  # PHP
  [ -z "${PHP_MEMORY_LIMIT+x}" ]        && PHP_MEMORY_LIMIT="2048M" && QUERY_PHP="yes"
  [ -z "${PHP_MAX_EXECUTION_TIME+x}" ]  && PHP_MAX_EXECUTION_TIME="300" && QUERY_PHP="yes"
  [ -z "${PHP_UPLOAD_MAX_FILESIZE+x}" ] && PHP_UPLOAD_MAX_FILESIZE="50M" && QUERY_PHP="yes"
  [ -z "${PHP_POST_MAX_SIZE+x}" ]       && PHP_POST_MAX_SIZE="50M" && QUERY_PHP="yes"
  
  # DEPRECATED: HTTP
  [ -n "${HTTP_PORT+x}" ]            && PROXY_HTTP_PORT="$HTTP_PORT"
  [ -n "${HTTPS_PORT+x}" ]           && PROXY_HTTPS_PORT="$HTTPS_PORT"
  [ -n "${HTTP_SERVERADMIN+x}" ]     && MAIL_CONTACT_ADDRESS="$HTTP_SERVERADMIN"
  # shellcheck disable=SC2154
  [ -n "${ALLOW_ALL_IPs+x}" ]        && PROXY_QUESTION_USE_IP_RESTRICTION="$ALLOW_ALL_IPs"
  # shellcheck disable=SC2154
  [ -n "${client_max_body_size+x}" ] && PROXY_CLIENT_MAX_BODY_SIZE="$client_max_body_size"
  [ -n "${HTTP_ALLOWED_IP+x}" ]         && PROXY_IP_RESTRICTION="$HTTP_ALLOWED_IP"
  # END DEPRECATED
  # Reverse Proxy
  [ -z "${PROXY_HTTP_PORT+x}" ]                   && PROXY_HTTP_PORT="80" && QUERY_HTTP="yes"
  [ -z "${PROXY_HTTPS_PORT+x}" ]                  && PROXY_HTTPS_PORT="443" && QUERY_HTTP="yes"
  [ -z "${PROXY_QUESTION_USE_IP_RESTRICTION+x}" ] && PROXY_QUESTION_USE_IP_RESTRICTION="yes" && QUERY_HTTP="yes"
  [ -z "${PROXY_CLIENT_MAX_BODY_SIZE+x}" ]        && PROXY_CLIENT_MAX_BODY_SIZE="$PHP_UPLOAD_MAX_FILESIZE" && QUERY_HTTP="yes"
  [ -z "${PROXY_IP_RESTRICTION+x}" ]              && PROXY_IP_RESTRICTION="all" && QUERY_HTTP="yes"
  [ -z "${PROXY_BASIC_AUTH_USER+x}" ]             && PROXY_BASIC_AUTH_USER="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 10)" && QUERY_HTTP="yes"
  [ -z "${PROXY_BASIC_AUTH_PASSWORD+x}" ]         && PROXY_BASIC_AUTH_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" && QUERY_HTTP="yes"
  

  # DEPRECATED Postfix
  [ -n "${SENDER_ADDRESS+x}" ]       && MAIL_SENDER_ADDRESS="$SENDER_ADDRESS"
  [ -n "${DOMAIN+x}" ]               && MAIL_DOMAIN="$DOMAIN"
  [ -n "${RELAY_USER+x}" ]           && MAIL_RELAY_USER="$RELAY_USER"
  [ -n "${RELAY_PASSWORD+x}" ]       && MAIL_RELAY_PASSWORD="$RELAY_PASSWORD"
  [ -n "${RELAYHOST+x}" ]            && MAIL_RELAYHOST="$RELAYHOST"
  [ -n "${QUESTION_DEBUG_PEERS+x}" ] && MAIL_QUESTION_DEBUG_PEERS="$QUESTION_DEBUG_PEERS"
  # END DEPRECATED
  # Mail: misp-server & misp-postfix
  [ -z "${MAIL_DOMAIN+x}" ]               && MAIL_DOMAIN="example.com" && QUERY_MAIL="yes"
  [ -z "${MAIL_SENDER_ADDRESS+x}" ]       && MAIL_SENDER_ADDRESS="no-reply@${MAIL_DOMAIN}" && QUERY_MAIL="yes"
  [ -z "${MAIL_CONTACT_ADDRESS+x}" ]      && MAIL_CONTACT_ADDRESS="support.misp@${MAIL_DOMAIN}" && QUERY_MAIL="yes"
  [ -z "${MAIL_RELAY_USER+x}" ]           && MAIL_RELAY_USER="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 10)" && QUERY_MAIL="yes"
  [ -z "${MAIL_RELAY_PASSWORD+x}" ]       && MAIL_RELAY_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" && QUERY_MAIL="yes"
  [ -z "${MAIL_RELAYHOST+x}" ]            && MAIL_RELAYHOST="mail.example.com" && QUERY_MAIL="yes"
  [ -z "${MAIL_QUESTION_DEBUG_PEERS+x}" ] && MAIL_QUESTION_DEBUG_PEERS="no" && QUERY_MAIL="yes"
  [ -z "${MAIL_ENABLE+x}" ] && MAIL_ENABLE="yes" && QUERY_MAIL="yes"

  # DEPRECATED SMIME / PGP
  [ -n "${USE_PGP+x}" ]   && PGP_ENABLE="$USE_PGP"
  [ -n "${USE_SMIME+x}" ] && SMIME_ENABLE="$USE_SMIME"
  # END DEPRECATED
  # SMIME / PGP
  [ -z "${PGP_ENABLE+x}" ]   && PGP_ENABLE="no" && QUERY_PGP="yes"
  [ -z "${SMIME_ENABLE+x}" ] && SMIME_ENABLE="no" && QUERY_SMIME="yes"
  
  # DEPRECATED: Redis
  #[ -z "${USE_EXTERNAL_REDIS}" ] && USE_EXTERNAL_REDIS="yes" && QUERY_REDIS="yes"
  # END DEPRECATED
  # Redis
  [ -z "${REDIS_FQDN+x}" ] && REDIS_FQDN="misp-redis"  && QUERY_REDIS="yes"
  [ -z "${REDIS_PORT+x}" ] && REDIS_PORT="6379" && QUERY_REDIS="yes"
  [ -z "${REDIS_PW+x}" ]   && REDIS_PW="" && QUERY_REDIS="yes"
  
  # DEPRECATED LOG_SETTINGS
  [ -n "${USE_SYSLOG+x}" ] && SYSLOG_QUESTION_USE_SYSLOG="$USE_SYSLOG"
  # END DEPRECATED
  # LOG_SETTINGS
  [ -z "${SYSLOG_QUESTION_USE_SYSLOG+x}" ]      && SYSLOG_QUESTION_USE_SYSLOG="no" && QUERY_LOG_SETTINGS="yes"
  [ -z "${SYSLOG_REMOTE_HOST+x}" ]              && SYSLOG_REMOTE_HOST="127.0.0.1" && QUERY_LOG_SETTINGS="yes"
  
  # Cron
  [ -z "${CRON_INTERVAL+x}" ] && CRON_INTERVAL=3600 && QUERY_CRON="yes"
  [ -z "${CRON_USER_ID+x}" ]  && CRON_USER_ID=1 && QUERY_CRON="yes"

  # Timezone
  [ -z "${TZ+x}" ] && TZ="Europe/Berlin" && QUERY_TIMEZONE="yes"
  
  # MISP-Modules
  [ -z "${MISP_MODULES_DEBUG+x}" ] && MISP_MODULES_DEBUG="false" && QUERY_MISP_MODULES="yes"
  
  # SSL
  [ -z "${SSL_PASSPHRASE_ENABLE+x}" ] && SSL_PASSPHRASE_ENABLE="no" && QUERY_SSL="yes"
  [ -z "${SSL_PASSPHRASE+x}" ] && SSL_PASSPHRASE="" && QUERY_SSL="yes"
  # [ -z "${SSL_PASSPHRASE_NGINX_CUSTOM_FILE+x}" ] && SSL_PASSPHRASE_NGINX_CUSTOM_FILE="ssl.passphrase" && QUERY_SSL="yes"


  #
  echo "...done"
}

#################################################
##  main part
#################################################
# Override Registry if it is set via parameter
[ -n "${PARAMETER_DOCKER_REGISTRY-}" ] && DOCKER_REGISTRY="$PARAMETER_DOCKER_REGISTRY"
# if vars not exists
func_check_if_vars_exists
# Docker Registry
func_query_docker_registry
# change to currents container
func_default_container_version
# check if its automated?
if [ "${AUTOMATE_BUILD-}" = "true" ]
  then
    ################################################
    # Automated Startup only for travis
    ################################################
    # ask no questions only defaults
    info "Automatic build..."
    ####
    # set hostname to an fix one
    MISP_FQDN="misp.example.com"
    MISP_BASEURL="https://$MISP_FQDN"

  else
    info "Manual build ..."
    # Hostname
    [ "${QUERY_myHOSTNAME-}" = "yes" ] && func_query_hostname
    # Network
    [ "${QUERY_NETWORK-}" = "yes" ] && func_query_network_settings
    # DB
    [ "${QUERY_DB-}" = "yes" ] && func_query_db_settings
    # MISP
    [ "${QUERY_MISP-}" = "yes" ] && func_query_misp_settings
    # HTTP
    [ "${QUERY_HTTP-}" = "yes" ] && func_query_reverse_proxy_settings
    # PROXY
    [ "${QUERY_PROXY-}" = "yes" ] && func_query_system_proxy_settings
    # Postfix
    [ "${QUERY_MAIL-}" = "yes" ] && func_query_mail_settings
    # Redis
    [ "${QUERY_REDIS-}" = "yes" ] && func_query_redis_settings
    # SMIME
    [ "${QUERY_SMIME-}" = "yes" ] && func_query_smime_settings
    # PGP
    [ "${QUERY_PGP-}" = "yes" ] && func_query_pgp_settings
    # LOG_SETTINGS
    [ "${QUERY_LOG_SETTINGS-}" = "yes" ] && func_query_log_settings
    # CRON
    [ "${QUERY_CRON-}" = "yes" ] && func_query_cron_settings
    # PHP
    [ "${QUERY_PHP-}" = "yes" ] && func_query_php_settings
    # Timezone
    [ "${QUERY_TIMEZONE-}" = "yes" ] && func_query_timezone
    # MISP MODULES
    [ "${QUERY_MISP_MODULES-}" = "yes" ] && func_query_misp_modules
    # Timezone
    [ "${QUERY_SSL-}" = "yes" ] && func_query_ssl
    # Latest, but unsupported MISP-Server
    [ "${QUERY_LATEST_MISP_SERVER-}" = "yes" ] && func_query_latest_misp_server
fi

[ "$MISP_QUESTION_USE_NIGHTLY_BUILD" = "yes" ] && MISP_CONTAINER_TAG=$MISP_NIGHTLY_TAG

if [ "${DEV_MODE-}" = "true" ] || [ "${DOCKER_REGISTRY-}" != "dcso" ] ; 
then
  IMAGE_MISP_MODULES="image: ${DOCKER_REGISTRY}/misp-dockerized-misp-modules:${MISP_MODULES_CONTAINER_TAG}"
  IMAGE_MISP_SERVER="image: ${DOCKER_REGISTRY}/misp-dockerized-server:${MISP_CONTAINER_TAG}"
  IMAGE_MISP_PROXY="image: ${DOCKER_REGISTRY}/misp-dockerized-proxy:${PROXY_CONTAINER_TAG}"
  IMAGE_MISP_ROBOT="image: ${DOCKER_REGISTRY}/misp-dockerized-robot:${ROBOT_CONTAINER_TAG}"
  IMAGE_MISP_REDIS="image: ${DOCKER_REGISTRY}/misp-dockerized-redis:${REDIS_CONTAINER_TAG}"
  #IMAGE_MISP_POSTFIX="image: ${DOCKER_REGISTRY}/misp-dockerized-postfix:${POSTFIX_CONTAINER_TAG}"
  IMAGE_MISP_DB="image: ${DOCKER_REGISTRY}/misp-dockerized-db:${DB_CONTAINER_TAG}"
  IMAGE_MISP_MONITORING="image: ${DOCKER_REGISTRY}/misp-dockerized-monitoring:${MONITORING_CONTAINER_TAG}"
fi

###################################
# Write Configuration
info_same_line "Write configuration in $DOCKER_COMPOSE_OVERRIDE ..."
###################################
# Docker-compose override File
cat << EOF > "$DOCKER_COMPOSE_OVERRIDE"
version: '3.1'

networks: 
  misp-backend:
    driver_opts:
     com.docker.network.bridge.name: "${NETWORK_BRIDGE_NAME}"
     # com.docker.network.bridge.host_binding_ipv4: "${NETWORK_BINDING_IPv4}"
    ipam:
      config:
      - subnet: "${NETWORK_CONTAINER_ADDRESS_RANGE}"

services:
  misp-db:
    ${IMAGE_MISP_DB-}
    environment:
      # DB
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      # Timezone
      TZ: ${TZ-}
    ${LOG_SETTINGS-}

  misp-redis:
     ${IMAGE_MISP_REDIS-}
     ${LOG_SETTINGS-}

  misp-modules:
    ${IMAGE_MISP_MODULES-}
    environment:
      # System PROXY
      http_proxy: ${CONTAINER_SYSTEM_HTTP_PROXY-}
      https_proxy: ${CONTAINER_SYSTEM_HTTPS_PROXY-}
      no_proxy: ${CONTAINER_SYSTEM_NO_PROXY-}
      # Redis
      REDIS_BACKEND: ${REDIS_FQDN}
      REDIS_PORT: "${REDIS_PORT}"
      REDIS_PW: "${REDIS_PW}"
      REDIS_DATABASE: "245"
      # Timezone
      TZ: ${TZ-}
      # MISP-Modules
      MISP_MODULES_DEBUG: "${MISP_MODULES_DEBUG}"
      # Logging options
      LOG_SYSLOG_ENABLED: "${SYSLOG_QUESTION_USE_SYSLOG}"
    ${LOG_SETTINGS-}

  misp-server:
    ${IMAGE_MISP_SERVER-}
    # ports:
    #   - "8080:80" # DEBUG only
    #   - "8443:443" # DEBUG only
    environment:
      # System PROXY
      http_proxy: ${CONTAINER_SYSTEM_HTTP_PROXY-}
      https_proxy: ${CONTAINER_SYSTEM_HTTPS_PROXY-}
      no_proxy: ${CONTAINER_SYSTEM_NO_PROXY-}
      # DB
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_HOST: ${DB_HOST}
      MYSQL_PORT: ${DB_PORT}
      # Redis
      REDIS_FQDN: "${REDIS_FQDN}"
      REDIS_PORT: "${REDIS_PORT}"
      REDIS_PW: "${REDIS_PW}"
      # Mail
      MAIL_SENDER_ADDRESS: "${MAIL_SENDER_ADDRESS}"
      MAIL_DOMAIN: "${MAIL_DOMAIN}"
      MAIL_CONTACT_ADDRESS: "${MAIL_CONTACT_ADDRESS}"
      MAIL_RELAYHOST: "${MAIL_RELAYHOST}"
      MAIL_RELAY_USER: "${MAIL_RELAY_USER}"
      MAIL_RELAY_PASSWORD: "${MAIL_RELAY_PASSWORD}"
      MAIL_QUESTION_DEBUG_PEERS: "${MAIL_QUESTION_DEBUG_PEERS}"
      MAIL_ENABLE: "${MAIL_ENABLE}"
      # MISP
      MISP_FQDN: ${MISP_FQDN}
      MISP_BASEURL: ${MISP_BASEURL}
      MISP_HTTPS_PORT: ${MISP_HTTPS_PORT}
      MISP_PREFIX: ${MISP_PREFIX}
      MISP_ENCODING: ${MISP_ENCODING}
      MISP_SALT: ${MISP_SALT}
      MISP_ADD_EVENT_ANALYZE_COLUMN: "${MISP_ADD_EVENT_ANALYZE_COLUMN}"
      # Mail Encryption
      PGP_ENABLE: "${PGP_ENABLE}"
      SMIME_ENABLE: "${SMIME_ENABLE}"
      # Cron
      CRON_INTERVAL: "${CRON_INTERVAL}"
      CRON_USER_ID: "${CRON_USER_ID}"
      # PHP
      PHP_MEMORY_LIMIT: "${PHP_MEMORY_LIMIT}"
      PHP_MAX_EXECUTION_TIME: "${PHP_MAX_EXECUTION_TIME}"
      PHP_POST_MAX_SIZE: "${PHP_POST_MAX_SIZE}"
      PHP_UPLOAD_MAX_FILESIZE: "${PHP_UPLOAD_MAX_FILESIZE}"
      # Timezone
      TZ: "${TZ-}"
      # SSL
      SSL_PASSPHRASE_ENABLE: "${SSL_PASSPHRASE_ENABLE}"
      SSL_PASSPHRASE: "${SSL_PASSPHRASE}"
      # Logging options
      LOG_SYSLOG_ENABLED: "${SYSLOG_QUESTION_USE_SYSLOG}"
    ${LOG_SETTINGS-}

  misp-proxy:
    ${IMAGE_MISP_PROXY-}
    environment:
      # MISP
      MISP_FQDN: "${MISP_FQDN}"
      # Mail
      MAIL_CONTACT_ADDRESS: "${MAIL_CONTACT_ADDRESS}"
      # Reverse Proxy
      PROXY_IP_RESTRICTION: "${PROXY_IP_RESTRICTION}"
      PROXY_HTTPS_PORT: "${PROXY_HTTPS_PORT}"
      PROXY_HTTP_PORT: "${PROXY_HTTP_PORT}"
      PROXY_QUESTION_USE_IP_RESTRICTION: "${PROXY_QUESTION_USE_IP_RESTRICTION}"
      PROXY_CLIENT_MAX_BODY_SIZE: "${PROXY_CLIENT_MAX_BODY_SIZE}"
      PROXY_BASIC_AUTH_USER: "${PROXY_BASIC_AUTH_USER}"
      PROXY_BASIC_AUTH_PASSWORD: "${PROXY_BASIC_AUTH_PASSWORD}"
      # Timezone
      TZ: "${TZ-}"
      # SSL
      SSL_PASSPHRASE_ENABLE: "${SSL_PASSPHRASE_ENABLE}"
      SSL_PASSPHRASE: "${SSL_PASSPHRASE}"
      # Logging options
      LOG_SYSLOG_ENABLED: "${SYSLOG_QUESTION_USE_SYSLOG}"
    ${LOG_SETTINGS-}

  misp-robot:
    ${IMAGE_MISP_ROBOT-}
    environment:
      # System PROXY
      http_proxy: ${CONTAINER_SYSTEM_HTTP_PROXY-}
      https_proxy: ${CONTAINER_SYSTEM_HTTPS_PROXY-}
      no_proxy: ${CONTAINER_SYSTEM_NO_PROXY-}
      # MISP
      MISP_FQDN: "${MISP_FQDN}"
      MISP_BASEURL: "${MISP_BASEURL}"
      # Timezone
      TZ: "${TZ-}"
      # Logging options
      LOG_SYSLOG_ENABLED: "${SYSLOG_QUESTION_USE_SYSLOG}"
    volumes:
    # Github Repository
    - ${MISP_dockerized_repo}:/srv/MISP-dockerized
    ${LOG_SETTINGS-}

  misp-monitoring:
    ${IMAGE_MISP_MONITORING-}
    #hostname: "${MISP_FQDN}"
    environment:
      # DB
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_HOST: ${DB_HOST}
      MYSQL_PORT: ${DB_PORT}
      # MISP
      MISP_FQDN: "${MISP_FQDN}"
      # Redis
      REDIS_FQDN: "${REDIS_FQDN}"
      REDIS_PORT: "${REDIS_PORT}"
      REDIS_PW: "${REDIS_PW}"
      # Timezone
      TZ: "${TZ-}"
      # Netdata
      PGID: $(grep docker /etc/group | cut -d ':' -f 3) # grep docker /etc/group | cut -d ':' -f 3 | 999
      SEND_EMAIL: "yes"
      EMAIL_SENDER: ${MAIL_SENDER_ADDRESS}
      DEFAULT_RECIPIENT_EMAIL: ${MAIL_CONTACT_ADDRESS}
      # Logging options
      LOG_SYSLOG_ENABLED: "${SYSLOG_QUESTION_USE_SYSLOG}"
    ${LOG_SETTINGS-}

EOF
###############################################
echo "done"
info_same_line "Write configuration in $CONFIG_FILE..."
#####################################
# ALL Variables
cat << EOF > "$CONFIG_FILE"
#description     :This file is the global configuration file
#=================================================

# ------------------------------
# Cron
# ------------------------------
CRON_INTERVAL="${CRON_INTERVAL}"
CRON_USER_ID="${CRON_USER_ID}"

# ------------------------------
# Container System Proxy
# ------------------------------
CONTAINER_SYSTEM_QUESTION_USE_PROXY="${CONTAINER_SYSTEM_QUESTION_USE_PROXY}"
CONTAINER_SYSTEM_HTTP_PROXY="${CONTAINER_SYSTEM_HTTP_PROXY}"
CONTAINER_SYSTEM_HTTPS_PROXY="${CONTAINER_SYSTEM_HTTPS_PROXY}"
CONTAINER_SYSTEM_NO_PROXY="${CONTAINER_SYSTEM_NO_PROXY}"

# ------------------------------
# Container Tags
# ------------------------------
#POSTFIX_CONTAINER_TAG=${POSTFIX_CONTAINER_TAG}
#MISP_CONTAINER_TAG=${MISP_CONTAINER_TAG}
#PROXY_CONTAINER_TAG=${PROXY_CONTAINER_TAG}
#ROBOT_CONTAINER_TAG=${ROBOT_CONTAINER_TAG}
#MISP_MODULES_CONTAINER_TAG=${MISP_MODULES_CONTAINER_TAG}
#REDIS_CONTAINER_TAG=${REDIS_CONTAINER_TAG}
#DB_CONTAINER_TAG=${DB_CONTAINER_TAG}

# ------------------------------
# DB
# ------------------------------
DB_QUESTION_OWN_DB="${DB_QUESTION_OWN_DB}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_DATABASE="${DB_DATABASE}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD}"

# ------------------------------
# Docker Registry Environment
# ------------------------------
DOCKER_REGISTRY=${DOCKER_REGISTRY}

# ------------------------------
# Network Configuration
# ------------------------------
NETWORK_CONTAINER_ADDRESS_RANGE="${NETWORK_CONTAINER_ADDRESS_RANGE}"
NETWORK_BRIDGE_NAME="${NETWORK_BRIDGE_NAME}"
NETWORK_BINDING_IPv4="${NETWORK_BINDING_IPv4}"


# ------------------------------
# Logging (Syslog)
# ------------------------------
SYSLOG_QUESTION_USE_SYSLOG="${SYSLOG_QUESTION_USE_SYSLOG}"
SYSLOG_REMOTE_HOST="${SYSLOG_REMOTE_HOST}"

# ------------------------------
# Mail
# ------------------------------
MAIL_DOMAIN="${MAIL_DOMAIN}"
MAIL_RELAYHOST="${MAIL_RELAYHOST}"
MAIL_RELAY_USER="${MAIL_RELAY_USER}"
MAIL_RELAY_PASSWORD="${MAIL_RELAY_PASSWORD}"
MAIL_SENDER_ADDRESS="${MAIL_SENDER_ADDRESS}"
MAIL_QUESTION_DEBUG_PEERS="${MAIL_QUESTION_DEBUG_PEERS}"
MAIL_CONTACT_ADDRESS="${MAIL_CONTACT_ADDRESS}"
MAIL_ENABLE="${MAIL_ENABLE}"

# ------------------------------
# Mail Encryption / Signing
# ------------------------------
PGP_ENABLE="${PGP_ENABLE}"
SMIME_ENABLE="${SMIME_ENABLE}"

# ------------------------------
# MISP
# ------------------------------
MISP_FQDN="${MISP_FQDN}"
MISP_BASEURL="${MISP_BASEURL}"
MISP_HTTPS_PORT="${MISP_HTTPS_PORT}"
MISP_PREFIX="${MISP_PREFIX}"
MISP_ENCODING="${MISP_ENCODING}"
MISP_SALT="${MISP_SALT}"
MISP_ADD_EVENT_ANALYZE_COLUMN="${MISP_ADD_EVENT_ANALYZE_COLUMN}"

# ------------------------------
# MISP Container
# ------------------------------
MISP_NIGHTLY_TAG="${MISP_NIGHTLY_TAG}"
MISP_QUESTION_USE_NIGHTLY_BUILD="${MISP_QUESTION_USE_NIGHTLY_BUILD}"

# ------------------------------
# MISP-Modules
# ------------------------------
MISP_MODULES_DEBUG="${MISP_MODULES_DEBUG}"

# ------------------------------
# Redis
# ------------------------------
REDIS_FQDN="${REDIS_FQDN}"
REDIS_PW="${REDIS_PW}"
REDIS_PORT="${REDIS_PORT}"

# ------------------------------
# Reverse Proxy
# ------------------------------
PROXY_HTTP_PORT="${PROXY_HTTP_PORT}"
PROXY_HTTPS_PORT="${PROXY_HTTPS_PORT}"
PROXY_CLIENT_MAX_BODY_SIZE="${PROXY_CLIENT_MAX_BODY_SIZE}"
PROXY_IP_RESTRICTION="${PROXY_IP_RESTRICTION}"
PROXY_QUESTION_USE_IP_RESTRICTION="${PROXY_QUESTION_USE_IP_RESTRICTION}"
PROXY_BASIC_AUTH_USER="${PROXY_BASIC_AUTH_USER}"
PROXY_BASIC_AUTH_PASSWORD="${PROXY_BASIC_AUTH_PASSWORD}"

# ------------------------------
# PHP
# ------------------------------
PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT}"
PHP_MAX_EXECUTION_TIME="${PHP_MAX_EXECUTION_TIME}"
PHP_POST_MAX_SIZE="${PHP_POST_MAX_SIZE}"
PHP_UPLOAD_MAX_FILESIZE="${PHP_UPLOAD_MAX_FILESIZE}"

# ------------------------------
# Timezone
# ------------------------------
TZ="${TZ}"

# ------------------------------
# Timezone
# ------------------------------
SSL_PASSPHRASE_ENABLE="${SSL_PASSPHRASE_ENABLE}"
SSL_PASSPHRASE="${SSL_PASSPHRASE}"

##################################################################

EOF
###############################################

echo "done"
echo
warn "To change the configuration, delete the corresponding line in:"
echo "$STARTMSG $CONFIG_FILE"
echo
sleep 2
##########################################
