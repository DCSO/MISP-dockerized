#!/bin/bash
#description     :This script build the configuration for the MISP Container and their content.
#==============================================================================
#set -xe # for debugging only

# check if this is an automate build not ask any questions
[ "$CI" = true ] && AUTOMATE_BUILD=true

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
MISP_dockerized_repo="$SCRIPTPATH/.."
CONFIG_FILE="${MISP_dockerized_repo}/config/config.env"
DOCKER_COMPOSE_CONF="${MISP_dockerized_repo}/.env"
DOCKER_COMPOSE_FILE="${MISP_dockerized_repo}/docker-compose.yml"
MISP_CONF_YML="${MISP_dockerized_repo}/config/misp.conf.yml"
BACKUP_PATH="${MISP_dockerized_repo}/backup"
######################################################################
# Function to import configuration
function import_config(){
  echo -n "check and import existing configuration..."
  [ -f $DOCKER_COMPOSE_CONF ] && source $DOCKER_COMPOSE_CONF
  [ -f $CONFIG_FILE ] && source $CONFIG_FILE
  echo "done"
}
# Function to set default values
function check_if_vars_exists() {
  echo -n "check if all vars exists..."
  # Default Variables for the config:
  # Hostname
  [ -z "$HOSTNAME" ] && query_hostname
  # Network
  [ -z "$DOCKER_NETWORK" ] && query_network_settings 
  [ -z "$BRIDGE_NAME" ] && query_network_settings
  # DB
  [ -z "$QUESTION_OWN_DB" ] && query_db_settings
  [ -z "$MYSQL_HOST" ]  && query_db_settings
  [ -z "$MYSQL_PORT" ]  && query_db_settings
  [ -z "$MYSQL_DATABASE" ]  && query_db_settings
  [ -z "$MYSQL_USER" ]  && query_db_settings
  [ -z "$MYSQL_PASSWORD" ]  && query_db_settings
  [ -z "$MYSQL_ROOT_PASSWORD" ]  && query_db_settings
  # MISP
  #[ -z "$MISP_prefix" ] && query_misp_settings
  #[ -z "$MISP_encoding" ] && query_misp_settings
  [ -z "$MISP_SALT" ] && query_misp_settings
  # HTTP
  [ -z "$HTTP_PORT" ] && query_http_settings
  [ -z "$HTTPS_PORT" ] && query_http_settings
  [ -z "$HTTP_SERVERADMIN" ] && query_http_settings
  [ -z "$ALLOW_ALL_IPs" ] && query_http_settings
  [ -z "$client_max_body_size" ] && query_http_settings
  [ -z "$HTTP_ALLOWED_IP" ] && query_http_settings
  # PROXY
  [ -z "$QUESTION_USE_PROXY" ] && query_proxy_settings
  [ -z "$HTTP_PROXY" ] && query_proxy_settings
  [ -z "$HTTPS_PROXY" ] && query_proxy_settings
  [ -z "$NO_PROXY" ] && query_proxy_settings
  # Postfix
  [ -z "$DOMAIN" ] && query_postfix_settings
  [ -z "$RELAY_USER" ] && query_postfix_settings
  [ -z "$RELAY_PASSWORD" ] && query_postfix_settings
  [ -z "$RELAYHOST" ] && query_postfix_settings
  [ -z "$QUESTION_DEBUG_PEERS" ] && query_postfix_settings
  # Redis
  [ -z "$REDIS_FQDN" ] && query_redis_settings
  [ -z "$REDIS_PORT" ] && query_redis_settings
  [ -z "$REDIS_PW" ] && query_redis_settings
  echo "...done"
}
# Function for the Container Versions
function default_container_version() {
  ############################################
  # Start Global Variable Section
  ############################################
  DB_CONTAINER_TAG="10.3"
  REDIS_CONTAINER_TAG="4.0-alpine"
  POSTFIX_CONTAINER_TAG="1.0.0-alpine"
  MISP_CONTAINER_TAG="2.4.92-ubuntu"
  PROXY_CONTAINER_TAG="1.0.1-alpine"
  ROBOT_CONTAINER_TAG="1.0.2-ubuntu"
  MISP_MODULES_CONTAINER_TAG="1.0.0-debian"
  ###
  MISP_TAG=$(echo $MISP_CONTAINER_TAG|cut -d - -f 1)
  ######################  END GLOBAL  ###########
}

# Start Function Section
function check_exists_configs(){
  # Init variables
  EXIT_COMPOSE=0
  EXIT_ANSIBLE=0
  # check config file and backup if its needed
  if [[ -f $DOCKER_COMPOSE_CONF ]]; then
    read -r -p "A docker-compose config file exists and will be overwritten, are you sure you want to contine? [y/N] " -ei "n" response
    case $response in
      [yY][eE][sS]|[yY])
        # move existing configuration in backup folder and add the date of this movement
        cp $DOCKER_COMPOSE_CONF $BACKUP_PATH/.env-backup_`date +%Y%m%d_%H_%M`
        EXIT_COMPOSE=0
        ;;
      *)
        EXIT_COMPOSE=1
      ;;
    esac
  fi
  # check config file and backup if its needed
  if [[ -f $MISP_CONF_YML ]]; then
    read -r -p "A misp config file exists and will be overwritten, are you sure you want to continue? [y/N] " -ei "n" response
    case $response in
      [yY][eE][sS]|[yY])
        # move existing configuration in backup folder and add the date of this movement
        cp $MISP_CONF_YML $BACKUP_PATH/misp.conf.yml-backup_`date +%Y%m%d_%H_%M`
        EXIT_ANSIBLE=0
        ;;
      *)
        EXIT_ANSIBLE=1
      ;;
    esac
  fi

  # chek if both want to exit:
  [ "$EXIT_ANSIBLE" == "$EXIT_COMPOSE" ] && [ "$EXIT_ANSIBLE" == "1" ] && exit 0;
  echo
}

function query_misp_tag(){
  # read MISP Tag for MISP Instance
  read -p "Which MISP Tag we should install[default: $MISP_TAG: " -ei "$MISP_TAG" MISP_TAG
}

function query_timezone(){
  # check Timezone
  if [[ -a /etc/timezone ]]; then
    TZ=$(cat /etc/timezone)
  elif  [[ -a /etc/localtime ]]; then
    TZ=$(readlink /etc/localtime|sed -n 's|^.*zoneinfo/||p')
  fi

  # approve checked Timezone
  if [ -z "$TZ" ]; then
    read -p "Timezone: " -ei "Europe/Berlin" TZ
  else
    read -p "Timezone: " -ei ${TZ} TZ
  fi
}

function query_hostname(){
  # set default values
  [ -z "$HOSTNAME" ] && HOSTNAME="`hostname -f`"
  # read Hostname for MISP Instance
  read -p "Hostname (FQDN - example.org is not a valid FQDN) [DEFAULT: $HOSTNAME]: " -ei $HOSTNAME HOSTNAME
}

function query_network_settings(){
  [ -z "$DOCKER_NETWORK" ] && DOCKER_NETWORK="192.168.47.0/28"
  [ -z "$BRIDGE_NAME" ] && BRIDGE_NAME="mispbr0"

  read -p "Which MISP Network should we use [DEFAULT: $DOCKER_NETWORK]: " -ei $DOCKER_NETWORK DOCKER_NETWORK
  read -p "Which MISP Network BRIDGE Interface Name should we use [DEFAULT: $BRIDGE_NAME]: " -ei $BRIDGE_NAME BRIDGE_NAME
}

function query_proxy_settings(){
  # set default values
  [ -z "$QUESTION_USE_PROXY" ] && QUESTION_USE_PROXY="no"
  [ -z "$HTTP_PROXY" ] && HTTP_PROXY=""
  [ -z "$HTTPS_PROXY" ] && HTTPS_PROXY=""
  [ -z "$NO_PROXY" ] && NO_PROXY=""

  # read Proxy Settings MISP Instance
  while (true)
  do
    read -r -p "Should we use http proxy? [y/N] " -ei "$QUESTION_USE_PROXY" QUESTION_USE_PROXY
    case $QUESTION_USE_PROXY in
      [yY][eE][sS]|[yY])
        QUESTION_USE_PROXY="yes"
        read -p "Which proxy we should use for HTTPS connections (for example: http://proxy.example.com:8080) [DEFAULT: $HTTPS_PROXY]: " -ei "$HTTPS_PROXY" HTTPS_PROXY
        read -p "Which proxy we should use for HTTP  connections (for example: http://proxy.example.com:8080) [DEFAULT: $HTTP_PROXY]: " -ei "$HTTP_PROXY" HTTP_PROXY
        read -p "For which site(s) we shouldn't use a Proxy (for example: localhost,127.0.0.0/8,docker-registry.somecorporation.com) [DEFAULT: $NO_PROXY]: " -ei $NO_PROXY NO_PROXY
        break
        ;;
      [nN][oO]|[nN])
        # do nothing
        QUESTION_USE_PROXY="no"
        break
        ;;
      *)
        echo -e "\nplease only choose [y|n] for the question!\n"
      ;;
    esac
  done  
}

function query_db_settings(){
  # set default DB Settings
  [ -z "$QUESTION_OWN_DB" ] && QUESTION_OWN_DB="no"
  [ -z "$MYSQL_HOST" ] && MYSQL_HOST="localhost" 
  [ -z "$MYSQL_PORT" ] && MYSQL_PORT="3306" 
  [ -z "$MYSQL_DATABASE" ] && MYSQL_DATABASE="misp" 
  [ -z "$MYSQL_USER" ] && MYSQL_USER="misp"
  [ -z "$MYSQL_PASSWORD" ] && MYSQL_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)"
  [ -z "$MYSQL_ROOT_PASSWORD" ] && MYSQL_ROOT_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)"
  # check if a own DB is needed
    while (true)
    do
      read -r -p "Do you want to use an external Database? [y/N] " -ei "$QUESTION_OWN_DB" QUESTION_OWN_DB
      case $QUESTION_OWN_DB in
        [yY][eE][sS]|[yY])
          QUESTION_OWN_DB="yes"
          read -p "Which DB Host should we use for DB Connection [DEFAULT: $MYSQL_HOST]: " -ei "$MYSQL_HOST" MYSQL_HOST
          read -p "Which DB Port should we use for DB Connection [DEFAULT: $MYSQL_PORT]: " -ei "$MYSQL_PORT" MYSQL_PORT
          break;
          ;;
        [nN][oO]|[nN])
          QUESTION_OWN_DB="no"
          # Set MISP_host to DB Container Name and Port
          echo "Set DB Host to docker default: $MYSQL_HOST"
          echo "Set DB Host Port to docker default: $MYSQL_PORT"
          read -p "Which DB Root Password should we use for DB Connection [DEFAULT: generated]: " -ei "$MYSQL_ROOT_PASSWORD" MYSQL_ROOT_PASSWORD
          break;
          ;;
        [eE][xX][iI][tT])
          exit 1
          ;;
        *)
          echo -e "\nplease only choose [y|n] for the question!\n"
      esac
    done
  read -p "Which DB Name should we use for DB Connection [DEFAULT: $MYSQL_DATABASE]: " -ei "$MYSQL_DATABASE" MYSQL_DATABASE
  read -p "Which DB User should we use for DB Connection [DEFAULT: $MYSQL_USER]: " -ei "$MYSQL_USER" MYSQL_USER
  read -p "Which DB User Password should we use for DB Connection [DEFAULT: generated]: " -ei "$MYSQL_PASSWORD" MYSQL_PASSWORD

}

function query_http_settings(){
  [ -z "$HTTP_PORT" ] && HTTP_PORT="80"
  [ -z "$HTTPS_PORT" ] && HTTPS_PORT="443"
  [ -z "$HTTP_SERVERADMIN" ] && HTTP_SERVERADMIN="admin@${HOSTNAME}"
  [ -z "$ALLOW_ALL_IPs" ] && ALLOW_ALL_IPs="yes"
  [ -z "$client_max_body_size" ] && client_max_body_size="50M"
  [ -z "$HTTP_ALLOWED_IP" ] && HTTP_ALLOWED_IP="all"
  
  # read HTTP Settings
  read -p "Which HTTPS Port should we expose [DEFAULT: $HTTPS_PORT]: " -ei "$HTTPS_PORT" HTTPS_PORT
  read -p "Which HTTP Port should we expose [DEFAULT: $HTTP_PORT]: " -ei "$HTTP_PORT" HTTP_PORT
  read -p "Which HTTP Serveradmin mailadress should we use [DEFAULT: $HTTP_SERVERADMIN]: " -ei "$HTTP_SERVERADMIN" HTTP_SERVERADMIN
 
  ### DEACTIVATED
  # while (true)
  # do
  #   read -r -p "Should we allow access to misp from every IP? [y/N] " -ei "$ALLOW_ALL_IPs" ALLOW_ALL_IPs
  #   case $ALLOW_ALL_IPs in
  #     [yY][eE][sS]|[yY])
  #       ALLOW_ALL_IPs=yes
  #       break
  #       ;;
  #     [nN][oO]|[nN])
  #       ALLOW_ALL_IPs=no
  #       read -p "Which IPs should have access? [DEFAULT: 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8]: " -ei "$HTTP_ALLOWED_IP" HTTP_ALLOWED_IP
  #       break
  #       ;;
  #     [eE][xX][iI][tT])
  #       exit 1
  #       ;;
  #     *)
  #       echo -e "\nplease only choose [y|n] for the question!\n"
  #     ;;
  #   esac
  # done
}

function query_misp_settings(){
  [ -z "$MISP_prefix" ] && MISP_prefix=""
  [ -z "$MISP_encoding" ] && MISP_encoding="utf8"
  [ -z "$MISP_SALT" ] && MISP_SALT="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 50)"
  # read and set MISP config settings
  # read -p "Which MISP DB prefix should we use [default: '']: " -ei $MISP_prefix MISP_prefix
  # read -p "Which MISP Encoding should we use [default: utf8]: " -ei $MISP_encoding  MISP_encoding
  read -p "If you do a fresh Installation, you should have a Salt. Is this SALT ok [DEFAULT: generated]: " -ei $MISP_SALT  MISP_SALT
}

function query_postfix_settings(){
  [ -z "$DOMAIN" ] && DOMAIN="example.com"
  [ -z "$RELAY_USER" ] && RELAY_USER="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 10)"
  [ -z "$RELAY_PASSWORD" ] && RELAY_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)"
  [ -z "$RELAYHOST" ] && RELAYHOST="mail.example.com"
  [ -z "$QUESTION_DEBUG_PEERS" ] && QUESTION_DEBUG_PEERS="no"

  read -p "Which mail domain we should use [DEFAULT: $DOMAIN]: " -ei $DOMAIN DOMAIN
  read -p "Which relay host we should use [ IP or DNS]: " -ei $RELAYHOST RELAYHOST
  read -p "Which relay user we should use [DEFAULT: generated]: " -ei $RELAY_USER RELAY_USER
  read -p "Which relay user password we should use [DEFAULT: generated]: " -ei $RELAY_PASSWORD RELAY_PASSWORD
  read -p "Which sender address we should use [MAIL]:" -ei $HTTP_SERVERADMIN SENDER_ADDRESS
  while (true)
  do
    read -r -p "Should we enable debugging options for a special peer? [y/N]: " -ei $QUESTION_DEBUG_PEERS QUESTION_DEBUG_PEERS
    case $QUESTION_DEBUG_PEERS in
      [yY][eE][sS]|[yY])
        QUESTION_DEBUG_PEERS=yes
        read -p "For which peer we need debug informations?: " -ei $DEBUG_PEER DEBUG_PEER
        break
        ;;
      [nN][oO]|[nN])
        QUESTION_DEBUG_PEERS=no
        DEBUG_PEER=none
        break
        ;;
      [eE][xX][iI][tT])
        exit 1
        ;;
      *)
        echo -e "\nplease only choose [y|n] for the question!\n"
      ;;
    esac
  done
}

function query_redis_settings(){
  [ -z "$REDIS_FQDN" ] && REDIS_FQDN="misp-server"
  [ -z "$REDIS_PORT" ] && REDIS_PORT=""
  [ -z "$REDIS_PW" ] && REDIS_PW=""
  # read -p "Which MISP DB prefix should we use [default: '']: " -ei $MISP_prefix MISP_prefix
  # read -p "Which MISP Encoding should we use [default: utf8]: " -ei $MISP_encoding  MISP_encoding
  #read -p "If you do a fresh Installation, you should have a Salt. Is this SALT ok [DEFAULT: generated]: " -ei $MISP_SALT  MISP_SALT
}

function query_pgp_settings(){
  echo
}

#################################################
########  main part
#################################################
# import existing .env
import_config
# if vars not exists
check_if_vars_exists
# change to currents container
default_container_version
# check if its automated?
if [ "$AUTOMATE_BUILD" = true ]
  then
    ################################################
    # Automated Startup only for travis
    ################################################
    # ask no questions only defaults
    echo "automatic build"
    ####
    POSTFIX_CONTAINER_TAG="$POSTFIX_CONTAINER_TAG-dev"
    MISP_CONTAINER_TAG="$MISP_CONTAINER_TAG-dev"
    PROXY_CONTAINER_TAG="$PROXY_CONTAINER_TAG-dev"
    ROBOT_CONTAINER_TAG="$ROBOT_CONTAINER_TAG-dev"
    MISP_MODULES_CONTAINER_TAG="$MISP_MODULES_CONTAINER_TAG-dev"
fi
###################################
# Write Configuration
echo -n "write configuration..."
###################################
# Only Docker Environment Variables
cat << EOF > $DOCKER_COMPOSE_CONF
#description     :This script set the Environment variables for the right MISP Docker Container and Environments
#=================================================
# ------------------------------
# Hostname
# ------------------------------
HOSTNAME=${HOSTNAME}
# ------------------------------
# Container Configuration
# ------------------------------
DB_CONTAINER_TAG=${DB_CONTAINER_TAG}
REDIS_CONTAINER_TAG=${REDIS_CONTAINER_TAG}
POSTFIX_CONTAINER_TAG=${POSTFIX_CONTAINER_TAG}
MISP_CONTAINER_TAG=${MISP_CONTAINER_TAG}
PROXY_CONTAINER_TAG=${PROXY_CONTAINER_TAG}
ROBOT_CONTAINER_TAG=${ROBOT_CONTAINER_TAG}
MISP_MODULES_CONTAINER_TAG=${MISP_MODULES_CONTAINER_TAG}
# ------------------------------
# Proxy Configuration
# ------------------------------
HTTP_PROXY=${HTTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY}
NO_PROXY=${NO_PROXY}
# ------------------------------
# DB configuration
# ------------------------------
#         ALL DB SETTINGS REQUIRED WITHOUT ""!!!
MYSQL_HOST=${MYSQL_HOST}
MYSQL_PORT=${MYSQL_PORT}
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
# ------------------------------
# HTTP/S configuration
# ------------------------------
HTTP_PORT=${HTTP_PORT}
HTTPS_PORT=${HTTPS_PORT}
# ------------------------------
# Redis configuration
# ------------------------------
REDIS_FQDN=misp-redis
REDIS_PW=
REDIS_PORT=
# ------------------------------
# Mail Configuration
# ------------------------------
DOMAIN=${DOMAIN}
RELAYHOST=${RELAYHOST}
RELAY_USER=${RELAY_USER}
RELAY_PASSWORD=${RELAY_PASSWORD}
SENDER_ADDRESS=${SENDER_ADDRESS}
DEBUG_PEER=${DEBUG_PEER}
DOCKER_NETWORK=${DOCKER_NETWORK}
##################################################################

EOF

# Only Ansible variables
cat << EOF > $MISP_CONF_YML
#description     :This Config sets the MISP Configuration inside the MISP Robot via Ansible
#=================================================
#
# MISP
#
# ------------------------------
# misp-db configuration
# ------------------------------
MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
MYSQL_HOST: ${MYSQL_HOST}
MYSQL_PORT: ${MYSQL_PORT}
MYSQL_DATABASE: ${MYSQL_DATABASE}
MYSQL_USER: ${MYSQL_USER}
MYSQL_PASSWORD: ${MYSQL_PASSWORD}
# ------------------------------
# misp-server configuration
# ------------------------------
MISP_FQDN: ${HOSTNAME}
MISP_HTTPS_PORT: ${HTTPS_PORT}
MISP_TAG: ${MISP_TAG}
MISP_prefix: ${MISP_prefix}
MISP_encoding: ${MISP_encoding}
MISP_SALT: ${MISP_SALT}
# ------------------------------
# misp-redis configuration
# ------------------------------
REDIS_FQDN: misp-redis
REDIS_passwort:
REDIS_port:
# ------------------------------
# misp-proxy configuration
# ------------------------------
client_max_body_size: "${client_max_body_size}"
ALLOW_ALL_IPs: "${ALLOW_ALL_IPs}"
HTTP_ALLOWED_IP: "${HTTP_ALLOWED_IP}"
HTTP_SERVERADMIN: "${HTTP_SERVERADMIN}"
# ------------------------------
# Postfix Configuration
# ------------------------------
DOMAIN: "${DOMAIN}"
RELAY_USER: "${RELAY_USER}"
DEBUG_PEER: "${DEBUG_PEER}"
SENDER_ADDRESS: "${SENDER_ADDRESS}"
DOCKER_NETWORK: "${DOCKER_NETWORK}"
RELAYHOST: "${RELAYHOST}"
RELAY_PASSWORD: "${RELAY_PASSWORD}"
##################################################################

EOF

# ALL Variables
cat << EOF > $CONFIG_FILE
#description     :This file is the global configuration file
#=================================================
# ------------------------------
# Hostname
# ------------------------------
HOSTNAME="${HOSTNAME}"
# ------------------------------
# Network Configuration
# ------------------------------
DOCKER_NETWORK="${DOCKER_NETWORK}"
BRIDGE_NAME="${BRIDGE_NAME}"
# ------------------------------
# Container Configuration
# ------------------------------
DB_CONTAINER_TAG=${DB_CONTAINER_TAG}
REDIS_CONTAINER_TAG=${REDIS_CONTAINER_TAG}
POSTFIX_CONTAINER_TAG=${POSTFIX_CONTAINER_TAG}
MISP_CONTAINER_TAG=${MISP_CONTAINER_TAG}
PROXY_CONTAINER_TAG=${PROXY_CONTAINER_TAG}
ROBOT_CONTAINER_TAG=${ROBOT_CONTAINER_TAG}
MISP_MODULES_CONTAINER_TAG=${MISP_MODULES_CONTAINER_TAG}
# ------------------------------
# Proxy Configuration
# ------------------------------
QUESTION_USE_PROXY="${QUESTION_USE_PROXY}"
HTTP_PROXY="${HTTP_PROXY}"
HTTPS_PROXY="${HTTPS_PROXY}"
NO_PROXY="${NO_PROXY}"
# ------------------------------
# DB configuration
# ------------------------------
#         ALL DB SETTINGS REQUIRED WITHOUT ""!!!
QUESTION_OWN_DB="${QUESTION_OWN_DB}"
MYSQL_HOST="${MYSQL_HOST}"
MYSQL_PORT="${MYSQL_PORT}"
MYSQL_DATABASE="${MYSQL_DATABASE}"
MYSQL_USER="${MYSQL_USER}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"
# ------------------------------
# misp-proxy configuration
# ------------------------------
HTTP_PORT="${HTTP_PORT}"
HTTPS_PORT="${HTTPS_PORT}"
client_max_body_size="${client_max_body_size}"
ALLOW_ALL_IPs="${ALLOW_ALL_IPs}"
HTTP_ALLOWED_IP="${HTTP_ALLOWED_IP}"
HTTP_SERVERADMIN="${HTTP_SERVERADMIN}"
# ------------------------------
# misp-redis configuration
# ------------------------------
REDIS_FQDN=misp-redis
REDIS_PW=
REDIS_PORT=
# ------------------------------
# misp-server env configuration
# ------------------------------
MISP_FQDN="${HOSTNAME}"
MISP_HTTPS_PORT="${HTTPS_PORT}"
MISP_TAG="${MISP_TAG}"
MISP_prefix="${MISP_prefix}"
MISP_encoding="${MISP_encoding}"
MISP_SALT="${MISP_SALT}"
# ------------------------------
# misp-postfix Configuration
# ------------------------------
DOMAIN="${DOMAIN}"
RELAYHOST="${RELAYHOST}"
RELAY_USER="${RELAY_USER}"
RELAY_PASSWORD="${RELAY_PASSWORD}"
SENDER_ADDRESS="${SENDER_ADDRESS}"
QUESTION_DEBUG_PEERS="${QUESTION_DEBUG_PEERS}"
DEBUG_PEER="${DEBUG_PEER}"
##################################################################

EOF

echo "...done"
##########################################
#
# Post-Tasks
#
echo -n "Start post tasks..."
# change docker-compose for network and bridge
sed -i 's/com.docker.network.bridge.name:.*/com.docker.network.bridge.name: "'${BRIDGE_NAME}'"/g' $DOCKER_COMPOSE_FILE
sed -i 's,subnet:.*,subnet: "'${DOCKER_NETWORK}'",g' $DOCKER_COMPOSE_FILE
echo "...done"
###########################################

