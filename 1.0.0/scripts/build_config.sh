#!/bin/bash
#description     :This script build the configuration for the MISP Container and their content.
#==============================================================================
set -e
#set -xv # for debugging only

# check if this is an automate build not ask any questions
[ "$CI" = true ] && AUTOMATE_BUILD=true

# full path <version>/scripts
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
# full path in <version>
MISP_dockerized_repo=$(echo ${SCRIPTPATH%/*})
# full path in the git repository
MISP_dockerized_repo=$(echo ${MISP_dockerized_repo%/*})
CONFIG_FILE="${MISP_dockerized_repo}/config/config.env"
DOCKER_COMPOSE_CONF="${MISP_dockerized_repo}/current/docker-compose.override.yml"
DOCKER_COMPOSE_FILE="${MISP_dockerized_repo}/current/docker-compose.yml"
BACKUP_PATH="${MISP_dockerized_repo}/backup"
ENABLE_FILE_DCSO_DOCKER_REGISTRY="${MISP_dockerized_repo}/config/use_secure_DCSO_Docker_Registry.enable"
ENABLE_FILE_SMIME="${MISP_dockerized_repo}/config/smime/smime.enable"
ENABLE_FILE_PGP="${MISP_dockerized_repo}/config/pgp/pgp.enable"
######################################################################
# Function to import configuration
function import_config(){
  echo -n "check and import existing configuration..."
  [ -f $CONFIG_FILE ] && source $CONFIG_FILE
  echo "done"
}
# Function to set default values
function check_if_vars_exists() {
  echo -n "check if all vars exists..."
  # Default Variables for the config:
  # Hostname
  [ -z "${myHOSTNAME+x}" ] && myHOSTNAME="`hostname -f`" && QUERY_myHOSTNAME="yes"
  # Network
  [ -z "$DOCKER_NETWORK" ] && DOCKER_NETWORK="192.168.47.0/28" && QUERY_NETWORK="yes" 
  [ -z "$BRIDGE_NAME" ] && BRIDGE_NAME="mispbr0" && QUERY_NETWORK="yes"
  # PROXY
  [ -z "$QUESTION_USE_PROXY" ] && QUESTION_USE_PROXY="no" && QUERY_PROXY="yes"
  [ -z "${HTTP_PROXY+x}" ] && HTTP_PROXY="" && QUERY_PROXY="yes"
  [ -z "${HTTPS_PROXY+x}" ] && HTTPS_PROXY="" && QUERY_PROXY="yes"
  [ -z "$NO_PROXY" ] && NO_PROXY="0.0.0.0" && QUERY_PROXY="yes"
    # DB
  [ -z "$QUESTION_OWN_DB" ] && QUESTION_OWN_DB="no" && QUERY_DB="yes"
  [ -z "$MYSQL_HOST" ]  && MYSQL_HOST="localhost" && QUERY_DB="yes"
  [ -z "$MYSQL_PORT" ]  && MYSQL_PORT="3306" && QUERY_DB="yes"
  [ -z "$MYSQL_DATABASE" ]  && MYSQL_DATABASE="misp" && QUERY_DB="yes"
  [ -z "$MYSQL_USER" ]  && MYSQL_USER="misp" && QUERY_DB="yes"
  [ -z "$MYSQL_PASSWORD" ]  && MYSQL_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" && QUERY_DB="yes"
  [ -z "$MYSQL_ROOT_PASSWORD" ]  && MYSQL_ROOT_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" && QUERY_DB="yes"
    # HTTP
  [ -z "$HTTP_PORT" ] && HTTP_PORT="80" && QUERY_HTTP="yes"
  [ -z "$HTTPS_PORT" ] && HTTPS_PORT="443" && QUERY_HTTP="yes"
  [ -z "$HTTP_SERVERADMIN" ] && HTTP_SERVERADMIN="admin@${myHOSTNAME}" && QUERY_HTTP="yes"
  [ -z "$ALLOW_ALL_IPs" ] && ALLOW_ALL_IPs="yes" && QUERY_HTTP="yes"
  [ -z "$client_max_body_size" ] && client_max_body_size="50M" && QUERY_HTTP="yes"
  [ -z "$HTTP_ALLOWED_IP" ] && HTTP_ALLOWED_IP="all" && QUERY_HTTP="yes"
  [ -z "$PHP_MEMORY" ] && PHP_MEMORY="512M" && QUERY_HTTP="yes"
  # MISP
  [ -z "${MISP_prefix+x}" ] && MISP_prefix="" && QUERY_MISP="yes"
  [ -z "$MISP_encoding" ] && MISP_encoding="utf8" && QUERY_MISP="yes"
  [ -z "$MISP_SALT" ] && MISP_SALT="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 50)" && QUERY_MISP="yes"
  [ -z "$ADD_ANALYZE_COLUMN" ] && ADD_ANALYZE_COLUMN="no" && QUERY_MISP="yes"
  [ -z "$SENDER_ADDRESS" ] && SENDER_ADDRESS="admin@${myHOSTNAME}" && QUERY_MISP="yes"
  # Postfix
  [ -z "$DOMAIN" ] && DOMAIN="example.com" && QUERY_POSTFIX="yes"
  [ -z "$RELAY_USER" ] && RELAY_USER="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 10)" && QUERY_POSTFIX="yes"
  [ -z "$RELAY_PASSWORD" ] && RELAY_PASSWORD="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" && QUERY_POSTFIX="yes"
  [ -z "$RELAYHOST" ] && RELAYHOST="mail.example.com" && QUERY_POSTFIX="yes"
  [ -z "$QUESTION_DEBUG_PEERS" ] && QUESTION_DEBUG_PEERS="no" && QUERY_POSTFIX="yes"
  # Redis
  [ -z "$REDIS_FQDN" ] && REDIS_FQDN="misp-server"  && QUERY_REDIS="yes"
  [ -z "${REDIS_PORT}" ] && REDIS_PORT=""             && QUERY_REDIS="yes"
  [ -z "${REDIS_PW}" ]   && REDIS_PW=""               && QUERY_REDIS="yes"
  # SMIME / PGP
  [ -z "${USE_PGP}" ] && QUERY_PGP="yes"
  [ -z "${USE_SMIME}" ] && QUERY_SMIME="yes"
  # LOG_SETTINGS
  [ -z "${USE_SYSLOG}" ] && QUERY_LOG_SETTINGS="yes"
  [ ! "${USE_SYSLOG}" == "no" ]  && [ -z "${SYSLOG_REMOTE_HOST}" ] && SYSLOG_REMOTE_HOST="127.0.0.1" && QUERY_LOG_SETTINGS="yes"
  echo "...done"
}
# Function for the Container Versions
function default_container_version() {
  ############################################
  # Start Global Variable Section
  ############################################
  MISP_CONTAINER_TAG="$(cat $DOCKER_COMPOSE_FILE |grep image:|grep server|cut -d : -f 3)"
  PROXY_CONTAINER_TAG="$(cat $DOCKER_COMPOSE_FILE |grep image:|grep proxy|cut -d : -f 3)"
  ROBOT_CONTAINER_TAG="$(cat $DOCKER_COMPOSE_FILE |grep image:|grep robot|cut -d : -f 3)"
  MISP_MODULES_CONTAINER_TAG="$(cat $DOCKER_COMPOSE_FILE |grep image:|grep modules|cut -d : -f 3)"
  #[ -z $(echo $POSTFIX_CONTAINER_TAG|grep dev) ] && POSTFIX_CONTAINER_TAG="$POSTFIX_CONTAINER_TAG-dev"
  [ -z $(echo $MISP_CONTAINER_TAG|grep dev) ] && MISP_CONTAINER_TAG="$MISP_CONTAINER_TAG-dev"
  [ -z $(echo $PROXY_CONTAINER_TAG|grep dev) ] && PROXY_CONTAINER_TAG="$PROXY_CONTAINER_TAG-dev"
  [ -z $(echo $ROBOT_CONTAINER_TAG|grep dev) ] && ROBOT_CONTAINER_TAG="$ROBOT_CONTAINER_TAG-dev"
  [ -z $(echo $MISP_MODULES_CONTAINER_TAG|grep dev) ] && MISP_MODULES_CONTAINER_TAG="$MISP_MODULES_CONTAINER_TAG-dev"
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
        cp -av $DOCKER_COMPOSE_CONF $BACKUP_PATH/.env-backup_`date +%Y%m%d_%H_%M`
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

# Question to Timezone
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

# Questions for Hostname
function query_hostname(){
  # read Hostname for MISP Instance
  read -p "Hostname (FQDN - example.org is not a valid FQDN) [DEFAULT: $myHOSTNAME]: " -ei $myHOSTNAME myHOSTNAME
  MISP_FQDN="https://${myHOSTNAME}"
}

# Questions for Network
function query_network_settings(){
  read -p "Which MISP Network should we use [DEFAULT: $DOCKER_NETWORK]: " -ei $DOCKER_NETWORK DOCKER_NETWORK
  read -p "Which MISP Network BRIDGE Interface Name should we use [DEFAULT: $BRIDGE_NAME]: " -ei $BRIDGE_NAME BRIDGE_NAME
}

# Questions for Proxy Settings
function query_proxy_settings(){
  # read Proxy Settings MISP Instance
  while (true)
  do
    read -r -p "Should we use an proxy configuration? [y/N] " -ei "$QUESTION_USE_PROXY" QUESTION_USE_PROXY
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

# Questions for Database
function query_db_settings(){
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

# Questions for MISP-Server Webserver Settings
function query_http_settings(){
  # read HTTP Settings
  # deactivate because MISP does not allow redirection of port:
  #read -p "Which HTTPS Port should we expose [DEFAULT: $HTTPS_PORT]: " -ei "$HTTPS_PORT" HTTPS_PORT
  #read -p "Which HTTP Port should we expose [DEFAULT: $HTTP_PORT]: " -ei "$HTTP_PORT" HTTP_PORT
  
  
  read -p "Which HTTP Serveradmin mailadress should we use [DEFAULT: $HTTP_SERVERADMIN]: " -ei "$HTTP_SERVERADMIN" HTTP_SERVERADMIN
  read -p "How much PHP memory should be used? [DEFAULT: $PHP_MEMORY]: " -ei $PHP_MEMORY  PHP_MEMORY

  while (true)
  do
    read -r -p "Should we allow access to misp from every IP? [y/N] " -ei "$ALLOW_ALL_IPs" ALLOW_ALL_IPs
    case $ALLOW_ALL_IPs in
      [yY][eE][sS]|[yY])
        ALLOW_ALL_IPs=yes
        HTTP_ALLOWED_IP="all"
        break
        ;;
      [nN][oO]|[nN])
        ALLOW_ALL_IPs=no
        read -p "Which IPs should have access? [DEFAULT: 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8]: " -ei "$HTTP_ALLOWED_IP" HTTP_ALLOWED_IP
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

# Questions for MISP Settings into MISP-server
function query_misp_settings(){
  # read and set MISP config settings
  # read -p "Which MISP DB prefix should we use [default: '']: " -ei $MISP_prefix MISP_prefix
  # read -p "Which MISP Encoding should we use [default: utf8]: " -ei $MISP_encoding  MISP_encoding
  read -p "If you do a fresh Installation, you should have a Salt. Is this SALT ok [DEFAULT: generated]: " -ei $MISP_SALT  MISP_SALT
  read -p "Do you require the analyse column at List Events page? [DEFAULT: no]: " -ei $ADD_ANALYZE_COLUMN  ADD_ANALYZE_COLUMN
  read -p "Which sender mailadress should MISP use [DEFAULT: $SENDER_ADDRESS]: " -ei "$SENDER_ADDRESS" SENDER_ADDRESS
}

# Questions for Postfix Mailer
function query_postfix_settings(){
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

# Questions for Redis
function query_redis_settings(){
  echo
}

# Questions for PGP
function query_pgp_settings(){
  read -r -p "Would you start with PGP? [y/N] " -ei "n" response
  case $response in
  [yY][eE][sS]|[yY])
    touch $ENABLE_FILE_PGP
    USE_PGP="yes"
    ;;
  *)
    [ -e $ENABLE_FILE_PGP ] && rm -f $ENABLE_FILE_PGP
    USE_PGP="no"
    ;;
  esac
}

# Questions for S/MIME
function query_smime_settings(){
  read -r -p "Would you start with S/MIME? [y/N] " -ei "n" response
  case $response in
  [yY][eE][sS]|[yY])
    touch $ENABLE_FILE_SMIME
    USE_SMIME="yes"
    ;;
  *)
    [ -e $ENABLE_FILE_SMIME ] && rm -f $ENABLE_FILE_SMIME
    USE_SMIME="no"
    ;;
  esac
    
}

# Questions for Docker Registry
function query_docker_registry() {
  if [ -f $ENABLE_FILE_DCSO_DOCKER_REGISTRY ]
  then
    ############## FILE exists ##############
    echo
    echo "We switched the container repository to secure DCSO registry."
    echo "      If you want to use the public one from hub.docker.com,"
    echo "      please delete $ENABLE_FILE_DCSO_DOCKER_REGISTRY and 'make install'"
    echo
  
  else
    ##############  FILE not exists ##############
    [ "$AUTOMATE_BUILD" = "true" ] || read -r -p "Do you want to load the MISP containers from secure DCSO Registry? [Y/n] " -ei "y" response
    [ "$AUTOMATE_BUILD" = "true" ] && response="yes"
    [ "$TRAVIS" == "true" ] && response="no"
    case $response in
    [yY][eE][sS]|[yY])
      [ -d ${MISP_dockerized_repo}/config ] || mkdir -p ${MISP_dockerized_repo}/config
      touch $ENABLE_FILE_DCSO_DOCKER_REGISTRY
      echo "We switched the container repository to secure DCSO registry."
      echo "      If you want to use the public one from hub.docker.com,"
      echo "      please delete $ENABLE_FILE_DCSO_DOCKER_REGISTRY and 'make install'"
      [ "$AUTOMATE_BUILD" = "true" ] || read -r -p "     continue with ENTER"     
      ;;
    *)
      rm -f $ENABLE_FILE_DCSO_DOCKER_REGISTRY
      ;;
    esac
    
    if [ -e "$ENABLE_FILE_DCSO_DOCKER_REGISTRY" ]
    then
      # On our own registry we have none group tag, but we have another URL
      DOCKER_REGISTRY="dockerhub.dcso.de"
    else
      # PUBLIC one from hub.docker.com we need only the organistion group. Because the URL is the default one
      DOCKER_REGISTRY="dcso"
    fi
  
  fi
}

# Questions for Log Settings
function query_log_settings(){
  read -r -p "Would you enable Syslog logging? [y/N] " -ei "n" response
  case $response in
  [yY][eE][sS]|[yY])
    read -p "Do you require syslog logging to an remote host if yes, please enter Hostname, DNS or IP? [DEFAULT: $SYSLOG_REMOTE_HOST]: " -ei $SYSLOG_REMOTE_HOST  SYSLOG_REMOTE_HOST
    #syslog-address: "unix:///dev/log"
         #syslog-address: "unix:///tmp/syslog.sock"
    [ ! $SYSLOG_REMOTE_HOST == "no" ] && SYSLOG_REMOTE_LINE="syslog-address: tcp://$SYSLOG_REMOTE_HOST"

    LOG_SETTINGS='### LOG DRIVER ###
    # for more Information: https://docs.docker.com/compose/compose-file/#logging + https://docs.docker.com/config/containers/logging/syslog/
    logging:
      driver: syslog
      options:
        '$SYSLOG_REMOTE_LINE'
        # For Facility: https://tools.ietf.org/html/rfc5424#section-6.2.1
        #syslog-facility: "local7"
        #syslog-tls-cert: "/etc/ca-certificates/custom/cert.pem"
        #syslog-tls-key: "/etc/ca-certificates/custom/key.pem"
        #syslog-tls-skip-verify: "true"
        # For Tags: https://docs.docker.com/config/containers/logging/log_tags/
        tag: "{{.ImageName}}/{{.Name}}/{{.ID}}"
        #syslog-format: "rfc5424micro"
        #labels: "misp-dockerized"
        #env: "os,customer"
        #env-regex: "^(os\|customer)"
    '

    USE_SYSLOG="yes"
    ;;
  *)
    USE_SYSLOG="no"
    ;;
  esac
}

#################################################
########  main part
#################################################
# import existing .env
import_config
# if vars not exists
check_if_vars_exists
# Docker Registry
query_docker_registry
# change to currents container
default_container_version
# check if its automated?
if [ "$AUTOMATE_BUILD" = "true" ]
  then
    ################################################
    # Automated Startup only for travis
    ################################################
    # ask no questions only defaults
    echo "automatic build..."
    ####
    # set hostname to an fix one
    myHOSTNAME="misp.example.com"
    IMAGE_MISP_MODULES="image: ${DOCKER_REGISTRY}/misp-dockerized-misp-modules:${MISP_MODULES_CONTAINER_TAG}"
    IMAGE_MISP_SERVER="image: ${DOCKER_REGISTRY}/misp-dockerized-server:${MISP_CONTAINER_TAG}"
    IMAGE_MISP_PROXY="image: ${DOCKER_REGISTRY}/misp-dockerized-proxy:${PROXY_CONTAINER_TAG}"
    IMAGE_MISP_ROBOT="image: ${DOCKER_REGISTRY}/misp-dockerized-robot:${ROBOT_CONTAINER_TAG}"

  else
    echo "manual build..."
    # Hostname
    [ "$QUERY_myHOSTNAME" == "yes" ] && query_hostname
    # Network
    [ "$QUERY_NETWORK" == "yes" ] && query_network_settings
    # DB
    [ "$QUERY_DB" == "yes" ] && query_db_settings
    # MISP
    [ "$QUERY_MISP" == "yes" ] && query_misp_settings
    # HTTP
    [ "$QUERY_HTTP" == "yes" ] && query_http_settings
    # PROXY
    [ "$QUERY_PROXY" == "yes" ] && query_proxy_settings
    # Postfix
    [ "$QUERY_POSTFIX" == "yes" ] && query_postfix_settings
    # Redis
    [ "$QUERY_REDIS" == "yes" ] && query_redis_settings
    # SMIME
    [ "$QUERY_SMIME" == "yes" ] && query_smime_settings
    # PGP
    [ "$QUERY_PGP" == "yes" ] && query_pgp_settings
    # LOG_SETTINGS
    [ "$QUERY_LOG_SETTINGS" == "yes" ] && query_log_settings
    
    if [ "$DEV" == true ]
    then
      IMAGE_MISP_MODULES="image: ${DOCKER_REGISTRY}/misp-dockerized-misp-modules:${MISP_MODULES_CONTAINER_TAG}"
      IMAGE_MISP_SERVER="image: ${DOCKER_REGISTRY}/misp-dockerized-server:${MISP_CONTAINER_TAG}"
      IMAGE_MISP_PROXY="image: ${DOCKER_REGISTRY}/misp-dockerized-proxy:${PROXY_CONTAINER_TAG}"
      IMAGE_MISP_ROBOT="image: ${DOCKER_REGISTRY}/misp-dockerized-robot:${ROBOT_CONTAINER_TAG}"
    fi
fi
###################################
# Write Configuration
echo -n "write configuration..."
###################################
# Docker-compose override File
cat << EOF > $DOCKER_COMPOSE_CONF
version: '3.1'

networks: 
  misp-backend:
    driver_opts:
     com.docker.network.bridge.name: "${BRIDGE_NAME}"
    ipam:
      config:
      - subnet: "${DOCKER_NETWORK}"

services:
  # misp-db:
  #   environment:
  #     MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
  #     MYSQL_DATABASE: ${MYSQL_DATABASE}
  #     MYSQL_USER: ${MYSQL_USER}
  #     MYSQL_PASSWORD: ${MYSQL_PASSWORD}

  misp-modules:
    ${IMAGE_MISP_MODULES}
    environment:
      REDIS_FQDN: ${REDIS_FQDN}
      HTTP_PROXY: ${HTTP_PROXY}
      HTTPS_PROXY: ${HTTPS_PROXY}
      NO_PROXY: ${NO_PROXY}
    ${LOG_SETTINGS}

  misp-server:
    ${IMAGE_MISP_SERVER}
    # ports:
    #   - "8080:80" # DEBUG only
    #   - "8443:443" # DEBUG only
    environment:
      # DB
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      # REDIS
      REDIS_FQDN: ${REDIS_FQDN}
      # PROXY
      HTTP_PROXY: ${HTTP_PROXY}
      HTTPS_PROXY: ${HTTPS_PROXY}
      NO_PROXY: ${NO_PROXY}
      # POSTFIX
      SENDER_ADDRESS: ${SENDER_ADDRESS}
      DOMAIN: ${DOMAIN}
      HTTP_SERVERADMIN: ${HTTP_SERVERADMIN}
      RELAYHOST: ${RELAYHOST}
      RELAY_USER: ${RELAY_USER}
      RELAY_PASSWORD: ${RELAY_PASSWORD}
      DOCKER_NETWORK: ${DOCKER_NETWORK}
      DEBUG_PEER: ${DEBUG_PEER}
      # PHP
      PHP_MEMORY: ${PHP_MEMORY}
      # MISP
      MISP_FQDN: ${MISP_FQDN}
      MISP_HTTPS_PORT: ${HTTPS_PORT}
      MISP_prefix: ${MISP_prefix}
      MISP_encoding: ${MISP_encoding}
      MISP_SALT: ${MISP_SALT}
      ADD_ANALYZE_COLUMN: "${ADD_ANALYZE_COLUMN}"
      USE_PGP: "${USE_PGP}"
      USE_SMIME: "${USE_SMIME}"
      PHP_MEMORY: ${PHP_MEMORY}
    ${LOG_SETTINGS}

  misp-proxy:
    ${IMAGE_MISP_PROXY}
    environment:
      HOSTNAME: ${myHOSTNAME}
      HTTP_SERVERADMIN: ${HTTP_SERVERADMIN}
      HTTP_PROXY: ${HTTP_PROXY}
      HTTPS_PROXY: ${HTTPS_PROXY}
      NO_PROXY: ${NO_PROXY}
      IP: ${HTTP_ALLOWED_IP}
    ${LOG_SETTINGS}

  misp-robot:
    ${IMAGE_MISP_ROBOT}
    environment:
      HTTP_PROXY: ${HTTP_PROXY}
      HTTPS_PROXY: ${HTTPS_PROXY}
      NO_PROXY: ${NO_PROXY}
      HOSTNAME: ${myHOSTNAME}
    volumes:
    # Github Repository
    - ${MISP_dockerized_repo}:/srv/MISP-dockerized
    #- ${MISP_dockerized_repo}/current/playbooks:/etc/ansible/playbooks/robot-playbook:ro
    ${LOG_SETTINGS}

EOF
###############################################

#####################################
# ALL Variables
cat << EOF > $CONFIG_FILE
#description     :This file is the global configuration file
#=================================================
# ------------------------------
# Hostname
# ------------------------------
myHOSTNAME="${myHOSTNAME}"
MISP_FQDN="${MISP_FQDN}"
# ------------------------------
# Network Configuration
# ------------------------------
DOCKER_NETWORK="${DOCKER_NETWORK}"
BRIDGE_NAME="${BRIDGE_NAME}"
# ------------------------------
# Logging
# ------------------------------
USE_SYSLOG="${USE_SYSLOG}"
SYSLOG_REMOTE_HOST="${SYSLOG_REMOTE_HOST}"
# ------------------------------
# Docker Registry Environment Variables
# ------------------------------
DOCKER_REGISTRY=${DOCKER_REGISTRY}
# ------------------------------
# Container Configuration
# ------------------------------
#POSTFIX_CONTAINER_TAG=${POSTFIX_CONTAINER_TAG}
#MISP_CONTAINER_TAG=${MISP_CONTAINER_TAG}
#PROXY_CONTAINER_TAG=${PROXY_CONTAINER_TAG}
ROBOT_CONTAINER_TAG=${ROBOT_CONTAINER_TAG}
#MISP_MODULES_CONTAINER_TAG=${MISP_MODULES_CONTAINER_TAG}
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
REDIS_FQDN=${REDIS_FQDN}
REDIS_PW=${REDIS_PW}
REDIS_PORT=${REDIS_PORT}
# ------------------------------
# misp-server env configuration
# ------------------------------
MISP_FQDN="${MISP_FQDN}"
MISP_HTTPS_PORT="${HTTPS_PORT}"
MISP_TAG="${MISP_TAG}"
MISP_prefix="${MISP_prefix}"
MISP_encoding="${MISP_encoding}"
MISP_SALT="${MISP_SALT}"
ADD_ANALYZE_COLUMN="${ADD_ANALYZE_COLUMN}"
USE_PGP="${USE_PGP}"
USE_SMIME="${USE_SMIME}"
PHP_MEMORY="${PHP_MEMORY}"
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
###############################################

echo "...done"
echo
echo "To change the configuration, delete the corresponding line in:"
echo "$CONFIG_FILE"
sleep 2
##########################################
