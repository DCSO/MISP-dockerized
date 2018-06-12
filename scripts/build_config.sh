#!/bin/bash
#description     :This script build the configuration for the MISP Container and their content.
#==============================================================================
#set -xe # for debugging only
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
MISP_dockerized_repo="$SCRIPTPATH/.."
DOCKER_COMPOSE_CONF="${MISP_dockerized_repo}/config/.env"
DOCKER_COMPOSE_FILE="${MISP_dockerized_repo}/docker-compose.yml"
MISP_CONF_YML="${MISP_dockerized_repo}/config/misp.conf.yml"
BACKUP_PATH="${MISP_dockerized_repo}/backup"
######################################################################
# Default Variables for the config:
# General
HOSTNAME="misp.example.com"
DOMAIN="example.com"
QUESTION_USE_PROXY=no
HTTP_PROXY=""
HTTPS_PROXY=""
NO_PROXY="0.0.0.0"
DOCKER_NETWORK="192.168.47.0/28"
BRIDGE_NAME="mispbr01"
# DB
QUESTION_OWN_DB="no"
MYSQL_HOST="misp-db"
MYSQL_PORT="3306"
MYSQL_DATABASE="misp"
MYSQL_USER="misp"
MYSQL_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)"
MYSQL_ROOT_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)"
# MISP
MISP_prefix=""
MISP_encoding="utf8"
# HTTP
HTTP_PORT="80"
HTTPS_PORT="443"
HTTP_SERVERADMIN="admin@${HOSTNAME}"
ALLOW_ALL_IPs="no"
client_max_body_size="50M"
HTTP_ALLOWED_IP="192.168.0.0/16 172.16.0.0/12 10.0.0.0/8"
# Postfix
RELAY_USER="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 10)"
RELAY_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)"
RELAYHOST="mail.example.com"
QUESTION_DEBUG_PEERS="no"

############################################
# load variables from existing configuration , if exists:
[ -f $DOCKER_COMPOSE_CONF ] && source $DOCKER_COMPOSE_CONF
############################################

############################################
# Start Global Variable Section
############################################
DB_CONTAINER_TAG="10.3.5"
REDIS_CONTAINER_TAG="3.2.11"
POSTFIX_CONTAINER_TAG="1.0.0-alpine"
MISP_CONTAINER_TAG="2.4.92-ubuntu"
MISP_TAG=$(echo $MISP_CONTAINER_TAG|cut -d - -f 1)
PROXY_CONTAINER_TAG="1.0.1-alpine"
ROBOT_CONTAINER_TAG="1.0.2-ubuntu"
######################  END GLOBAL  ###########



# Start Function Section
function check_exists_configs(){
  # Init variables
  EXIT_COMPOSE=0
  EXIT_ANSIBLE=0
  # check config file and backup if its needed
  if [[ -f $DOCKER_COMPOSE_CONF ]]; then
    read -r -p "A docker-compose config file exists and will be overwritten, are you sure you want to contine? [y/N] " response
    case $response in
      [yY][eE][sS]|[yY])
        # move existing configuration in backup folder and add the date of this movement
        mv $DOCKER_COMPOSE_CONF $BACKUP_PATH/.env-backup_`date +%Y%m%d_%H_%M`
        EXIT_COMPOSE=0
        ;;
      *)
        EXIT_COMPOSE=1
      ;;
    esac
  fi
  # check config file and backup if its needed
  if [[ -f $MISP_CONF_YML ]]; then
    read -r -p "A misp config file exists and will be overwritten, are you sure you want to continue? [y/N] " response
    case $response in
      [yY][eE][sS]|[yY])
        # move existing configuration in backup folder and add the date of this movement
        mv $MISP_CONF_YML $BACKUP_PATH/misp.conf.yml-backup_`date +%Y%m%d_%H_%M`
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

function query_hostname(){
  # read Hostname for MISP Instance
  read -p "Hostname (FQDN - example.org is not a valid FQDN): " -ei $HOSTNAME HOSTNAME
}

function query_proxy(){
  # read Proxy Settings MISP Instance
  while (true)
  do
    read -r -p "Should we use http proxy? [y/N] " -ei "$QUESTION_USE_PROXY" QUESTION_USE_PROXY
    case $QUESTION_USE_PROXY in
      [yY][eE][sS]|[yY])
        QUESTION_USE_PROXY=yes
        read -p "Which proxy we should use for HTTPS (for example: http://proxy.example.com:80/) [default: none]: " -ei "$HTTPS_PROXY" HTTPS_PROXY
        read -p "Which proxy we should use for HTTP (for example: http://proxy.example.com:80/) [default: none]: " -ei "$HTTP_PROXY" HTTP_PROXY
        read -p "For which site(s) we shouldn't use a Proxy (for example: localhost,127.0.0.0/8,docker-registry.somecorporation.com) [default: 0.0.0.0]: " -ei $NO_PROXY NO_PROXY
        break
        ;;
      [nN][oO]|[nN])
        # do nothing
        QUESTION_USE_PROXY=no
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

function query_db_settings(){
  # read DB Settings
  
  # check if a own DB is needed
    while (true)
    do
      read -r -p "Do you want to use an existing Database? [y/N] " -ei "$QUESTION_OWN_DB" QUESTION_OWN_DB
      case $QUESTION_OWN_DB in
        [yY][eE][sS]|[yY])
          QUESTION_OWN_DB="yes"
          read -p "Which DB Host should we use for DB Connection: " -ei "$MYSQL_HOST" MYSQL_HOST
          read -p "Which DB Port should we use for DB Connection [default: 3306]: " -ei "$MYSQL_PORT" MYSQL_PORT
          break;
          ;;
        [nN][oO]|[nN])
          QUESTION_OWN_DB="no"
          # Set MISP_host to DB Container Name and Port
          MYSQL_HOST="misp-db"; echo "Set DB Host to docker default: $MYSQL_HOST"
          MYSQL_PORT=3306; echo "Set DB Host Port to docker default: $MYSQL_PORT"
          read -p "Which DB Root Password should we use for DB Connection [default: generated PW]: " -ei "$MYSQL_ROOT_PASSWORD" MYSQL_ROOT_PASSWORD
          break;
          ;;
        [eE][xX][iI][tT])
          exit 1
          ;;
        *)
          echo -e "\nplease only choose [y|n] for the question!\n"
      esac
    done
  read -p "Which DB Name should we use for DB Connection [default: misp]: " -ei "$MYSQL_DATABASE" MYSQL_DATABASE
  read -p "Which DB User should we use for DB Connection [default: misp]: " -ei "$MYSQL_USER" MYSQL_USER
  read -p "Which DB User Password should we use for DB Connection [default: generated PW]: " -ei "$MYSQL_PASSWORD" MYSQL_PASSWORD

}

function query_http_settings(){
  # read HTTP Settings
  read -p "Which HTTPS Port should we expose [default: 443]: " -ei "$HTTPS_PORT" HTTPS_PORT
  read -p "Which HTTP Port should we expose [default: 80]: " -ei "$HTTP_PORT" HTTP_PORT
  read -p "Which HTTP Serveradmin mailadress should we use [default: admin@${HOSTNAME}]: " -ei "$HTTP_SERVERADMIN" HTTP_SERVERADMIN
  while (true)
  do
    read -r -p "Should we allow access to misp from every IP? [y/N]" -ei "$ALLOW_ALL_IPs" ALLOW_ALL_IPs
    case $ALLOW_ALL_IPs in
      [yY][eE][sS]|[yY])
        ALLOW_ALL_IPs=yes
        break
        ;;
      [nN][oO]|[nN])
        ALLOW_ALL_IPs=no
        read -p "Which IPs should have access? [default: 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8]: " -ei "$HTTP_ALLOWED_IP" HTTP_ALLOWED_IP
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

function query_misp_settings(){
  # read and set MISP config settings
  read -p "Which MISP DB prefix should we use [default: '']: " -ei $MISP_prefix MISP_prefix
  read -p "Which MISP Encoding should we use [default: utf8]: " -ei $MISP_encoding  MISP_encoding
}

function query_postfix_settings(){
  read -p "Which mail domain we should use: " -ei $DOMAIN DOMAIN
  read -p "Which relay host we should use: " -ei $RELAYHOST RELAYHOST
  read -p "Which relay user we should use: " -ei $RELAY_USER RELAY_USER
  read -p "Which relay user password we should use: " -ei $RELAY_PASSWORD RELAY_PASSWORD
  read -p "Which sender address we should use: " -ei $HTTP_SERVERADMIN SENDER_ADDRESS
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

function query_network_settings(){
    read -p "Which MISP Network should we use [default: '192.168.47.0/28']: " -ei $DOCKER_NETWORK DOCKER_NETWORK
    read -p "Which MISP Network BRIDGE Interface Name should we use [default: 'mispbr0']: " -ei $BRIDGE_NAME BRIDGE_NAME
}

#################################################
# Start Execution:

if [ "$1" == "--automated-build" ]
  then
    ################################################
    # Automated Startup only for travis
    ################################################
    # ask no questions only defaults
    echo "automatic build"
    
  else
    ################################################
    # Normal Startup
    ################################################
    echo
    echo "########## Exists Configs ##########"
    check_exists_configs
    # deactivated for the current releases:
    #query_misp_tag
    echo
    echo "########## Hostname Configs ##########"
    query_hostname
    echo
    echo "########## Proxy Configs ##########"
    query_proxy
    echo
    echo "########## DB Configs ##########"
    query_db_settings
    echo
    echo "########## HTTP Configs ##########"
    query_http_settings
    echo
    echo "########## Postifx Configs ##########"
    query_postfix_settings
    echo
    echo "########## Network Configs ##########"
    query_network_settings
    # deactivated for the current releases:
    #echo
    #echo "########## MISP Settings ##########"
    #query_misp_settings
fi

# Write Configuration
cat << EOF > $DOCKER_COMPOSE_CONF
#!/bin/bash
#description     :This script set the Environment variables for the right MISP Docker Container and Environments
#=================================================
# ------------------------------
# Hostname
# ------------------------------
HOSTNAME=${HOSTNAME}
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
# ------------------------------
# Proxy Configuration
# ------------------------------
QUESTION_USE_PROXY=${QUESTION_USE_PROXY}
HTTP_PROXY=${HTTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY}
NO_PROXY=${NO_PROXY}
# ------------------------------
# DB configuration
# ------------------------------
QUESTION_OWN_DB=${QUESTION_OWN_DB}
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
ALLOW_ALL_IPs=${ALLOW_ALL_IPs}
HTTP_ALLOWED_IP="${HTTP_ALLOWED_IP}"
HTTP_SERVERADMIN="${HTTP_SERVERADMIN}"
# ------------------------------
# Redis configuration
# ------------------------------
  #nothing to do.
# ------------------------------
# misp-server env configuration
# ------------------------------
MISP_TAG=${MISP_TAG}
MISP_prefix=${MISP_prefix}
MISP_encoding=${MISP_encoding}
# ------------------------------
# Postfix Configuration
# ------------------------------
DOMAIN=${DOMAIN}
RELAYHOST=${RELAYHOST}
RELAY_USER=${RELAY_USER}
RELAY_PASSWORD=${RELAY_PASSWORD}
SENDER_ADDRESS=${SENDER_ADDRESS}
QUESTION_DEBUG_PEERS=${QUESTION_DEBUG_PEERS}
DEBUG_PEER=${DEBUG_PEER}
##################################################################

EOF
 
cat << EOF > $MISP_CONF_YML
#description     :This Config sets the MISP Configuration inside the MISP Robot via Ansible
#=================================================
#
# MISP
#
# ------------------------------
# MISP database configuration
# ------------------------------
MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
MYSQL_HOST: ${MYSQL_HOST}
MYSQL_PORT: ${MYSQL_PORT}
MYSQL_DATABASE: ${MYSQL_DATABASE}
MYSQL_USER: ${MYSQL_USER}
MYSQL_PASSWORD: ${MYSQL_PASSWORD}
# ------------------------------
# MISP server configuration
# ------------------------------
MISP_hostname: ${HOSTNAME}
MISP_hostport: ${HTTPS_PORT}
MISP_TAG: ${MISP_TAG}
# ------------------------------
# MISP redis configuration
# ------------------------------
REDIS_hostname: misp-redis
REDIS_passwort:
REDIS_port:
# ------------------------------
# MISP NGINX configuration
# ------------------------------
client_max_body_size: "client_max_body_size ${client_max_body_size}"
ALLOW_ALL_IPs: "${ALLOW_ALL_IPs}"
HTTP_ALLOWED_IP: "${HTTP_ALLOWED_IP}"
HTTP_SERVERADMIN: "${HTTP_SERVERADMIN}"
# ------------------------------
# Proxy Configuration
# ------------------------------
HTTP_PROXY: "${HTTP_PROXY}"
NO_PROXY: "${NO_PROXY}"
USE_PROXY: "${QUESTION_USE_PROXY}"
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
#
# Post-Tasks
#

# check if .env file exists and delete it
[ -e "$MISP_dockerized_repo/.env" ] && rm -f $MISP_dockerized_repo/.env
# copy new .env to docker-compose folder
  #cp -v $MISP_dockerized_repo/config/.env $MISP_dockerized_repo/.env
# hardlink to .env:
pushd $MISP_dockerized_repo
  ln config/.env .env
popd

# change docker-compose for network and bridge
sed -i 's/com.docker.network.bridge.name:.*/com.docker.network.bridge.name: "'${BRIDGE_NAME}'"/g' $DOCKER_COMPOSE_FILE
sed -i 's,subnet:.*,subnet: "'${DOCKER_NETWORK}'",g' $DOCKER_COMPOSE_FILE
