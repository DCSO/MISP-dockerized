#!/bin/bash

#
#   Global Variables for all Scripts
#

# Full Path <version>/scripts
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
# Full Path in <version>
MISP_dockerized_repo="${SCRIPTPATH%/*}"
# Full Path in the Git Repository
MISP_dockerized_repo="${MISP_dockerized_repo%/*}"
# PGP File Path 
PGP_PATH="${MISP_dockerized_repo}/config/pgp"
# SMIME File Path
SMIME_PATH="${MISP_dockerized_repo}/config/smime"
# PGP
PGP_KEYFILE="misp.asc"
# S/MIME
SMIME_CERT="cert.pem"
SMIME_KEY="key.pem"
# Web SSL / TLS 
SSL_CERT="cert.pem"
SSL_KEY="key.pem"
# Colors
NC='\033[0m' # No Color
COLOR_NC='\e[0m' # No Color
COLOR_WHITE='\e[1;37m'
COLOR_BLACK='\e[0;30m'
COLOR_BLUE='\e[0;34m'
COLOR_LIGHT_BLUE='\e[1;34m'
COLOR_GREEN='\e[0;32m'
COLOR_LIGHT_GREEN='\e[1;32m'
Light_Green='\e[1;32m'  
COLOR_CYAN='\e[0;36m'
COLOR_LIGHT_CYAN='\e[1;36m'
COLOR_RED='\e[0;31m'
COLOR_LIGHT_RED='\033[1;31m'
COLOR_PURPLE='\e[0;35m'
COLOR_LIGHT_PURPLE='\e[1;35m'
COLOR_BROWN='\e[0;33m'
COLOR_YELLOW='\033[1;33m'
COLOR_GRAY='\e[0;30m'
COLOR_LIGHT_GRAY='\e[0;37m'

# to add options to the echo command
echo () {
    command echo -e "$*" 
}
info (){
  command echo -e "${COLOR_LIGHT_GREEN}$STARTMSG $* ${NC}"
}

error (){
  command echo -e "${COLOR_LIGHT_RED}$STARTMSG $* ${NC}"
}

warn (){
  command echo -e "${COLOR_YELLOW}$STARTMSG $* ${NC}"
}

info_same_line(){
  command echo -en "${COLOR_LIGHT_GREEN}$STARTMSG $* ${NC}"
}

# first_version=5.100.2
# second_version=5.1.2
# if version_gt $first_version $second_version; then
#      echo "$first_version is greater than $second_version !"
# fi'
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }


#
#   Requirements
#
func_check_docker() {
    #
    #   Check DOCKER
    #
    info "Check Docker... "
    if [ -z "$(which docker)" ] 
        then
            STATUS="FAIL"
            error "[FAIL] Docker is not installed. \tPlease install it first!" 
        else
            echo "[OK] Docker is installed. \t\tOutput: $(docker -v)"   
    fi
}

func_check_git() {
    #
    #   Check GIT
    #
    info "Check Git... "
    if [ -z "$(which git)" ] 
        then
            STATUS="FAIL"
            error "[FAIL] Git is not installed. \t\t\tPlease install it first!"
        else
            info "[OK] Git is installed. \t\t\tOutput: $(git --version)"
    fi
}

func_check_URL(){
    #
    # CHECK required URLs
    #
    URL="$1"
    info "Check URL $URL... "

    [ "$CONTAINER_SYSTEM_QUESTION_USE_PROXY" = "yes" ] && PROXY=" -x $CONTAINER_SYSTEM_HTTPS_PROXY"
    OPTIONS="-vs --connect-timeout 60 -m 30 $PROXY"
    COMMAND="$(curl "$OPTIONS" "$URL" 2>&1|grep 'Connected to')"
    
    if [ -z "$COMMAND" ]
        then
            warn "[WARN] Check: $URL"
            warn "       Result: Connection not available."
        else
            info "[OK]   Check: $URL"
            info "       Result: $COMMAND."
    fi
}

check_folder_write(){
    #
    #   Check Write permissions
    #
    FOLDER="$1"
    info "Check write permissions $FOLDER ... "
    if [ ! -e "$FOLDER" ]
            then
                STATUS="FAIL"
                error "[FAIL] Can not create '$FOLDER' folder."
            else
                # user is in docker group
                info "[OK] Folder $FOLDER exists."
                touch "$FOLDER/test"
                if [ ! -e "$FOLDER/test" ]
                    then
                        STATUS="FAIL"
                        error "[FAIL] No write permissions in '$FOLDER'. Please ensure that user '${whoami}' has write permissions.'"
                    else
                        info "[OK] Testfile in '$FOLDER' can be created."
                        rm "$FOLDER/test"
                fi
        fi
}

#
#   END Requirements
#

#################################################
#################################################
#################################################
#################################################
#
# Build Configuration
#

# Function for the Container Versions
func_default_container_version() {
  info_same_line "Check container version... "
  # Container Tags
  [ -z "${SERVER_TAG-}" ] && SERVER_TAG="$(grep image: "$DOCKER_COMPOSE_FILE"|grep server|cut -d : -f 3)"
  [ -z "${PROXY_CONTAINER_TAG-}" ] && PROXY_CONTAINER_TAG="$(grep image: "$DOCKER_COMPOSE_FILE" |grep proxy|cut -d : -f 3)"
  [ -z "${ROBOT_CONTAINER_TAG-}" ] && ROBOT_CONTAINER_TAG="$(grep image: "$DOCKER_COMPOSE_FILE" |grep robot|cut -d : -f 3)"
  [ -z "${MISP_MODULES_CONTAINER_TAG-}" ] && MISP_MODULES_CONTAINER_TAG="$(grep image: "$DOCKER_COMPOSE_FILE" |grep modules|cut -d : -f 3)"
  [ -z "${POSTFIX_CONTAINER_TAG-}" ] && POSTFIX_CONTAINER_TAG="$(grep image: "$DOCKER_COMPOSE_FILE" |grep postfix|cut -d : -f 3)"
  [ -z "${REDIS_CONTAINER_TAG-}" ] && REDIS_CONTAINER_TAG="$(grep image: "$DOCKER_COMPOSE_FILE" |grep redis|cut -d : -f 3)"
  [ -z "${DB_CONTAINER_TAG-}" ] && DB_CONTAINER_TAG="$(grep image: "$DOCKER_COMPOSE_FILE" |grep db|cut -d : -f 3)"
  [ -z "${MONITORING_CONTAINER_TAG-}" ] && MONITORING_CONTAINER_TAG="$(grep image: "$DOCKER_COMPOSE_FILE" |grep monitoring|cut -d : -f 3)"
  if [ "${DEV_MODE-}" = true ]; then
    # shellcheck disable=SC2143
    [ -z "$(command echo "$POSTFIX_CONTAINER_TAG"|grep dev)" ] && POSTFIX_CONTAINER_TAG="$POSTFIX_CONTAINER_TAG-dev"
    # shellcheck disable=SC2143
    [ -z "$(command echo "$SERVER_TAG"|grep dev)" ] && SERVER_TAG="$SERVER_TAG-dev"
    # shellcheck disable=SC2143
    [ -z "$(command echo "$PROXY_CONTAINER_TAG"|grep dev)" ] && PROXY_CONTAINER_TAG="$PROXY_CONTAINER_TAG-dev"
    # shellcheck disable=SC2143
    [ -z "$(command echo "$ROBOT_CONTAINER_TAG"|grep dev)" ] && ROBOT_CONTAINER_TAG="$ROBOT_CONTAINER_TAG-dev"
    # shellcheck disable=SC2143
    [ -z "$(command echo "$MISP_MODULES_CONTAINER_TAG"|grep dev)" ] && MISP_MODULES_CONTAINER_TAG="$MISP_MODULES_CONTAINER_TAG-dev"
    # shellcheck disable=SC2143
    [ -z "$(command echo "$REDIS_CONTAINER_TAG"|grep dev)" ] && REDIS_CONTAINER_TAG="$REDIS_CONTAINER_TAG-dev"
    # shellcheck disable=SC2143
    [ -z "$(command echo "$DB_CONTAINER_TAG"|grep dev)" ] && DB_CONTAINER_TAG="$DB_CONTAINER_TAG-dev"
    # shellcheck disable=SC2143
    [ -z "$(command echo "$MONITORING_CONTAINER_TAG"|grep dev)" ] && MONITORING_CONTAINER_TAG="$MONITORING_CONTAINER_TAG-dev"
    # shellcheck disable=SC2143
    [ -z "$(command echo "$MISP_NIGHTLY_TAG"|grep dev)" ] && MISP_NIGHTLY_TAG="$MISP_NIGHTLY_TAG-dev"
  fi
  echo "done"
}

# Function to Check if Configuration Files exists
func_check_exists_configs(){
  # Init variables
  EXIT_COMPOSE=0
  # check config file and backup if its needed
  if [[ -f $DOCKER_COMPOSE_OVERRIDE ]]; then
    read -rp "$STARTMSG A docker-compose config file exists and will be overwritten, are you sure you want to contine? [y/N] " -ei "n" response
    case $response in
      [yY][eE][sS]|[yY])
        # move existing configuration in backup folder and add the date of this movement
        cp -av "$DOCKER_COMPOSE_OVERRIDE" "$BACKUP_PATH/docker-compose.override.yml_$(date +%Y%m%d_%H_%M)"
        EXIT_COMPOSE=0
        ;;
      *)
        EXIT_COMPOSE=1
      ;;
    esac
  fi

  # chek if both want to exit:
  [ "$EXIT_COMPOSE" == "1" ] && exit 0;
  echo
}

# Question to Timezone
func_query_timezone(){
  info "Check timezone ... "
  # check Timezone
  if [[ -a /etc/timezone ]]; then
    TZ=$(cat /etc/timezone)
  elif  [[ -a /etc/localtime ]]; then
    TZ=$(readlink /etc/localtime|sed -n 's|^.*zoneinfo/||p')
  fi

  [ -z "${TZ-}" ] && TZ="Europe/Berlin"
  read -rp "Which timezone should the contaner use: [Default: $TZ] " -ei "${TZ}" TZ

}

# Questions for Hostname
func_query_hostname(){
  info "Check hostname ... "
  # read Hostname for MISP Instance
  read -rp "$STARTMSG Hostname (FQDN - example.org is not a valid FQDN) [DEFAULT: $MISP_FQDN]: " -ei "$MISP_FQDN" MISP_FQDN
  [ -z "${MISP_BASEURL-}" ] && MISP_BASEURL="https://$MISP_FQDN"
  read -rp "$STARTMSG Your MISP baseurl [DEFAULT: https://$MISP_FQDN]: " -ei "$MISP_BASEURL" MISP_BASEURL
}

# Questions for Network
func_query_network_settings(){
  info "Check network settings ... "
  echo "Network settings... "
  read -rp "$STARTMSG Which MISP Network should we use [DEFAULT: $NETWORK_CONTAINER_ADDRESS_RANGE]: " -ei "$NETWORK_CONTAINER_ADDRESS_RANGE" NETWORK_CONTAINER_ADDRESS_RANGE
  read -rp "$STARTMSG Which MISP Network BRIDGE Interface Name should we use [DEFAULT: $NETWORK_BRIDGE_NAME]: " -ei "$NETWORK_BRIDGE_NAME" NETWORK_BRIDGE_NAME
  read -rp "$STARTMSG If MISP should only available on one interface, which one? [DEFAULT: $NETWORK_BINDING_IPv4]: " -ei "$NETWORK_BINDING_IPv4" NETWORK_BINDING_IPv4
  echo "To Activate this option please show at https://dcso.github.io/MISP-dockerized-docs/admin/docker/docker_bind_interface.html"
  echo "Continue in 10 seconds ... " && sleep 10
}

# Questions for System Proxy Settings
func_query_system_proxy_settings(){
  info "Check container system proxy settings ... "
  # read Proxy Settings MISP Instance
  while (true)
  do
    read -rp "$STARTMSG Should we use an proxy configuration? [yes/no] " -ei "$CONTAINER_SYSTEM_QUESTION_USE_PROXY" CONTAINER_SYSTEM_QUESTION_USE_PROXY
    case $CONTAINER_SYSTEM_QUESTION_USE_PROXY in
      [yY][eE][sS]|[yY])
        CONTAINER_SYSTEM_QUESTION_USE_PROXY="yes"
        read -rp "$STARTMSG Which proxy the container should use for HTTPS connections (for example: http://proxy.example.com:8080) [DEFAULT: $CONTAINER_SYSTEM_HTTPS_PROXY]: " -ei "$CONTAINER_SYSTEM_HTTPS_PROXY" CONTAINER_SYSTEM_HTTPS_PROXY
        read -rp "$STARTMSG Which proxy the container should use for HTTP  connections (for example: http://proxy.example.com:8080) [DEFAULT: $CONTAINER_SYSTEM_HTTP_PROXY]: " -ei "$CONTAINER_SYSTEM_HTTP_PROXY" CONTAINER_SYSTEM_HTTP_PROXY
        read -rp "$STARTMSG For which site(s) the container should not use a proxy (for example: localhost,127.0.0.0/8,docker-registry.somecorporation.com) [DEFAULT: $CONTAINER_SYSTEM_NO_PROXY]: " -ei "$CONTAINER_SYSTEM_NO_PROXY" CONTAINER_SYSTEM_NO_PROXY
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

# Questions for DB
func_query_db_settings(){
  info "Check database settings ... "
  # check if a own DB is needed
    while (true)
    do
      read -rp "$STARTMSG Do you want to use an external database? [y/N] " -ei "$DB_QUESTION_OWN_DB" DB_QUESTION_OWN_DB
      case $DB_QUESTION_OWN_DB in
        [yY][eE][sS]|[yY])
          DB_QUESTION_OWN_DB="yes"
          read -rp "$STARTMSG Which database host should we use for the connection [DEFAULT: $DB_HOST]: " -ei "$DB_HOST" DB_HOST
          read -rp "$STARTMSG Which database host port should we use for the connection [DEFAULT: $DB_PORT]: " -ei "$DB_PORT" DB_PORT
          [ "$DB_HOST" = "misp-db" ] && read -rp "$STARTMSG Which database root password should we use for the connection [DEFAULT: generated]: " -ei "$DB_ROOT_PASSWORD" DB_ROOT_PASSWORD
          break;
          ;;
        [nN][oO]|[nN])
          QUESTION_OWN_DB="no"
          # Set MISP_host to DB Container Name and Port
          echo "$STARTMSG Set database host to docker default: $DB_HOST"
          echo "$STARTMSG Set database host port to docker default: $DB_PORT"
          read -rp "$STARTMSG Which database root password should we use for the connection [DEFAULT: generated]: " -ei "$DB_ROOT_PASSWORD" DB_ROOT_PASSWORD
          break;
          ;;
        [eE][xX][iI][tT])
          exit 1
          ;;
        *)
          echo -e "\n$STARTMSG Please only choose [y|n] for the question!\n"
      esac
    done
  read -rp "$STARTMSG Which database name should we use for the connection [DEFAULT: $DB_DATABASE]: " -ei "$DB_DATABASE" DB_DATABASE
  read -rp "$STARTMSG Which database user should we use for the connection [DEFAULT: $DB_USER]: " -ei "$DB_USER" DB_USER
  read -rp "$STARTMSG Which database user password should we use for the connection [DEFAULT: generated]: " -ei "$DB_PASSWORD" DB_PASSWORD

}

# Questions for Reverse Proxy Settings
func_query_reverse_proxy_settings(){
  info "Check reverse proxy settings ... "
  # read HTTP Settings
  # deactivate because MISP does not allow redirection of port:
  #read -p "Which HTTPS Port should we expose [DEFAULT: $HTTPS_PORT]: " -ei "$HTTPS_PORT" HTTPS_PORT
  #read -p "Which HTTP Port should we expose [DEFAULT: $HTTP_PORT]: " -ei "$HTTP_PORT" HTTP_PORT

  while (true)
  do
    read -rp "$STARTMSG Should we allow access to misp from every IP? [y/N] " -ei "$PROXY_QUESTION_USE_IP_RESTRICTION" PROXY_QUESTION_USE_IP_RESTRICTION
    case $PROXY_QUESTION_USE_IP_RESTRICTION in
      [yY][eE][sS]|[yY])
        PROXY_QUESTION_USE_IP_RESTRICTION=yes
        PROXY_IP_RESTRICTION="all"
        break
        ;;
      [nN][oO]|[nN])
        PROXY_QUESTION_USE_IP_RESTRICTION=no
        read -rp "$STARTMSG Which IPs should have access? [DEFAULT: 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8]: " -ei "$PROXY_IP_RESTRICTION" PROXY_IP_RESTRICTION
        break
        ;;
      [eE][xX][iI][tT])
        exit 1
        ;;
      *)
        echo -e "\n$STARTMSG Please only choose [yes|no] for the question!\n"
      ;;
    esac
  done
}

# Questions for MISP Settings
func_query_misp_settings(){
  info "Check MISP settings ... "
  # read and set MISP config settings
  # Deactivated:
  # read -p "Which MISP DB prefix should we use [default: $MISP_PREFIX ]: " -ei "$MISP_PREFIX" MISP_PREFIX
  # read -p "Which MISP Encoding should we use [default: $MISP_ENCODING ]: " -ei "$MISP_ENCODING"  MISP_ENCODING
  read -rp "$STARTMSG If you do a fresh Installation, you should have a salt. Is this salt value ok ? [DEFAULT: generated]: " -ei "$MISP_SALT"  MISP_SALT
  read -rp "$STARTMSG Do you require the analyse column at list events page? [DEFAULT: no]: " -ei "$MISP_ADD_EVENT_ANALYZE_COLUMN"  MISP_ADD_EVENT_ANALYZE_COLUMN
  #read -rp "$STARTMSG Which sender mailadress should MISP use [DEFAULT: $MAIL_SENDER_ADDRESS]: " -ei "$MAIL_SENDER_ADDRESS" MAIL_SENDER_ADDRESS
}

# Questions for Mail
func_query_mail_settings(){
  info "Check mail settings ... "
  
  while (true)
  do
    read -rp "$STARTMSG Should the MISP enable mailing? [y/n]: " -ei "$MAIL_ENABLE" MAIL_ENABLE
    case $MAIL_ENABLE in
      [yY][eE][sS]|[yY])
        MAIL_ENABLE="yes"
        read -rp "$STARTMSG Which mail domain we should use [DEFAULT: $MAIL_DOMAIN]: " -ei "$MAIL_DOMAIN" MAIL_DOMAIN
        read -rp "$STARTMSG Which relay host we should use [ IP or DNS]: " -ei "$MAIL_RELAYHOST" MAIL_RELAYHOST
        read -rp "$STARTMSG Which relay user we should use [DEFAULT: generated]: " -ei "$MAIL_RELAY_USER" MAIL_RELAY_USER
        read -rp "$STARTMSG Which relay user password we should use [DEFAULT: generated]: " -ei "$MAIL_RELAY_PASSWORD" MAIL_RELAY_PASSWORD
        #read -rp "$STARTMSG Which sender address we should use [MAIL]:" -ei "$MAIL_SENDER_ADDRESS" MAIL_SENDER_ADDRESS
        read -rp "$STARTMSG Which sender mailadress should MISP use [DEFAULT: $MAIL_SENDER_ADDRESS]: " -ei "$MAIL_SENDER_ADDRESS" MAIL_SENDER_ADDRESS
        read -rp "$STARTMSG Which contact mailadress should we use [DEFAULT: $MAIL_CONTACT_ADDRESS]: " -ei "$MAIL_CONTACT_ADDRESS" MAIL_CONTACT_ADDRESS
        
        while (true)
        do
          read -rp "$STARTMSG Should we enable debugging options for a special peer? [y/n]: " -ei "$MAIL_QUESTION_DEBUG_PEERS" MAIL_QUESTION_DEBUG_PEERS
          case $MAIL_QUESTION_DEBUG_PEERS in
            [yY][eE][sS]|[yY])
              MAIL_QUESTION_DEBUG_PEERS=yes
              read -rp "$STARTMSG For which peer we need debug informations?: " -ei "$MAIL_DEBUG_PEERS" MAIL_DEBUG_PEERS
              break
              ;;
            [nN][oO]|[nN])
              MAIL_QUESTION_DEBUG_PEERS=no
              MAIL_DEBUG_PEERS="none"
              break
              ;;
            [eE][xX][iI][tT])
              exit 1
              ;;
            *)
              echo -e "\n$STARTMSG Please only choose [yes|no] for the question!\n"
            ;;
          esac
        done
      break
        ;;
      [nN][oO]|[nN])
      MAIL_ENABLE="no"
      break
        ;;
      [eE][xX][iI][tT])
        exit 1
        ;;
      *)
        echo -e "\n$STARTMSG Please only choose [yes|no] for the question!\n"
      ;;
    esac
  done
}

# Questions for Redis
func_query_redis_settings(){
  info "Check Redis settings ... "
  #
  # Since v.1.2.0 external Redis is default. 
  # But you can choose if you want misp-redis or any other external installed one.
  #

  # read -rp "$STARTMSG Do you want to use an external Redis database? [y/n]: " -ei "n"  response
  # case $response in
  # [yY][eE][sS]|[yY])
  #   USE_EXTERNAL_REDIS="yes"
    read -rp "$STARTMSG Which FQDN has the external redis database? [Example: $REDIS_FQDN ]: " -ei "$REDIS_FQDN"  REDIS_FQDN
    read -rp "$STARTMSG Which port has the external redis database? [Default: 6379 ]: " -ei "$REDIS_PORT"  REDIS_PORT
    read -rp "$STARTMSG Which password has the external redis database? [Default: '' (empty) ]: " -ei ""  REDIS_PW
  #   ;;
  # *)
  #   USE_EXTERNAL_REDIS="no"
  #   REDIS_FQDN="localhost"
  #   ;;
  # esac
}

# Questions for PGP
func_query_pgp_settings(){
  info "Check PGP settings ... "
  read -rp "$STARTMSG Would you start with PGP? [y/N] " -ei "$PGP_ENABLE" response
  case $response in
  [yY][eE][sS]|[yY])
    PGP_ENABLE="yes"
    # If pgp public or private key file not exists, but you would start with pgp, we exit.
    if [ ! -f "$PGP_PRIVATE_KEY" ] || [ ! -f "$PGP_PUBLIC_KEY" ] ;
    then
      error "[ERROR] No, PGP public and / or private key found in $PGP_PATH"
      exit 1
    fi
    ;;
  *)
    PGP_ENABLE="no"
    ;;
  esac
}

# Questions for S/MIME
func_query_smime_settings(){
  info "Check S/MIME settings ... "
  read -rp "$STARTMSG Would you start with S/MIME? [y/N] " -ei "$SMIME_ENABLE" response
  case $response in
  [yY][eE][sS]|[yY])
    SMIME_ENABLE="yes"
    # If smime cert or key file not exists, but you would start with smime, we exit.
    if [ ! -f "$SMIME_CERT" ] || [ ! -f "$SMIME_KEY" ] ;
    then
      error "[ERROR] No, S/MIME certificate and/or private key found in $SMIME_PATH"
      exit 1
    fi
    ;;
  *)
    SMIME_ENABLE="no"
    ;;
  esac
    
}

# Questions for Docker Registry
func_query_docker_registry() { 
  info_same_line "Check Docker registry settings ... "
  if [ -z "${DOCKER_REGISTRY-}" ]; then
    # Default use hub.docker.com
    DOCKER_REGISTRY="dcso"
    ############## FILE exists ##############
    echo "done"
    echo
    echo "We switched the container repository to secure DCSO registry."
    echo "      If you want to use the public one from hub.docker.com,"
    echo "      please change the parameter 'DOCKER_REGISTRY' at $CONFIG_FILE and 'make install'"
    echo
  else
    echo "done"
  fi
}

# Questions for Log Settings
func_query_log_settings(){
  info "Check log settings ... "
  read -rp "$STARTMSG Would you enable Syslog logging? [y/n] " -ei "$SYSLOG_QUESTION_USE_SYSLOG" SYSLOG_QUESTION_USE_SYSLOG
  case $SYSLOG_QUESTION_USE_SYSLOG in
  [yY][eE][sS]|[yY])
    SYSLOG_QUESTION_USE_SYSLOG="yes"
    read -rp "Do you require syslog logging to an remote host if yes, please enter Hostname or IP, if not leave the field empty ? [DEFAULT: $SYSLOG_REMOTE_HOST]: " -ei "$SYSLOG_REMOTE_HOST"  SYSLOG_REMOTE_HOST
    [ -n "$SYSLOG_REMOTE_HOST" ] && SYSLOG_REMOTE_LINE="syslog-address: tcp://$SYSLOG_REMOTE_HOST"
    [ -n "$SYSLOG_REMOTE_HOST" ] && echo "We use $SYSLOG_REMOTE_LINE to send docker logs. Continue in 5 seconds... " && sleep 5

    LOG_SETTINGS='### LOG DRIVER ###
    # for more Information: https://docs.docker.com/compose/compose-file/#logging + https://docs.docker.com/config/containers/logging/syslog/
    logging:
      driver: syslog
      options:
        '$SYSLOG_REMOTE_LINE'
        # For Facility: https://tools.ietf.org/html/rfc5424#section-6.2.1
        syslog-facility: "local7"
        #syslog-tls-cert: "/etc/ca-certificates/custom/cert.pem"
        #syslog-tls-key: "/etc/ca-certificates/custom/key.pem"
        #syslog-tls-skip-verify: "true"
        # For Tags: https://docs.docker.com/config/containers/logging/log_tags/
        tag: "{{.ImageName}} {{.Name}} {{.ID}}"
        #syslog-format: "rfc5424micro"
        #labels: "misp-dockerized"
        #env: "os,customer"
        #env-regex: "^(os\|customer)"
    '

    SYSLOG_QUESTION_USE_SYSLOG="yes"
    ;;
  *)
    SYSLOG_QUESTION_USE_SYSLOG="no"
    ;;
  esac
}

# Questions for CRON Settings
func_query_cron_settings(){
  info "Check cron settings ... "
  read -rp "$STARTMSG How often should the cronjob be started? [ Dafault: 3600(s) | 0 means deactivated ]: " -ei "$CRON_INTERVAL"  CRON_INTERVAL
  read -rp "$STARTMSG Which user id do you want to use for the cron job execution? [ Default: 1 ]: " -ei "$CRON_USER_ID"  CRON_USER_ID
  read -rp "$STARTMSG Which server ids do you want to use for the cron job execution? [ Default: 1 ]: " -ei "$CRON_SERVER_IDS"  CRON_SERVER_IDS
  echo "done"
}

# Questions for PHP Settings
func_query_php_settings(){
   info "Check PHP settings ... "
   read -rp "$STARTMSG Set PHP variable memory_limit? [ Default: $PHP_MEMORY_LIMIT ]: " -ei "$PHP_MEMORY_LIMIT"  PHP_MEMORY_LIMIT
   read -rp "$STARTMSG Set PHP variable max_execution_time? [ Default: $PHP_MAX_EXECUTION_TIME ]: " -ei "$PHP_MAX_EXECUTION_TIME"  PHP_MAX_EXECUTION_TIME
   read -rp "$STARTMSG Set PHP variable post_max_size? [ Default: $PHP_POST_MAX_SIZE ]: " -ei "$PHP_POST_MAX_SIZE"  PHP_POST_MAX_SIZE
   read -rp "$STARTMSG Set PHP variable upload_max_filesize? [ Default: $PHP_UPLOAD_MAX_FILESIZE ]: " -ei "$PHP_UPLOAD_MAX_FILESIZE"  PHP_UPLOAD_MAX_FILESIZE
}

func_query_misp_modules() {
   info "Check MISP module settings ... "
   read -rp "$STARTMSG Do you want to enable MISP-module debug mode? [ Default: $MISP_MODULES_DEBUG ]: " -ei "$MISP_MODULES_DEBUG"  MISP_MODULES_DEBUG
}

func_query_latest_misp_server() {
  info "Check MISP server version ... "
  read -rp "$STARTMSG Do you want to enable nightly unsupported MISP server container? [ Default: $MISP_QUESTION_USE_NIGHTLY_BUILD ]: " -ei "$MISP_QUESTION_USE_NIGHTLY_BUILD"  MISP_QUESTION_USE_NIGHTLY_BUILD
  case $MISP_QUESTION_USE_NIGHTLY_BUILD in
  [yY][eE][sS]|[yY])
    SERVER_TAG=$MISP_NIGHTLY_TAG
    ;;
  *)
    command echo
    ;;
  esac
}

func_query_ssl() {
  info "Check SSL configuration ... "
  read -rp "$STARTMSG Do you want to enable SSL passphrase capabilities? [ Default: $SSL_PASSPHRASE_ENABLE ]: " -ei "$SSL_PASSPHRASE_ENABLE"  SSL_PASSPHRASE_ENABLE
  case $SSL_PASSPHRASE_ENABLE in
  [yY][eE][sS]|[yY])
    SSL_PASSPHRASE_ENABLE="yes"
    read -rp "$STARTMSG Which SSL passphrase should we set? (You can leave it empty and we files.) : " -ei "$SSL_PASSPHRASE"  SSL_PASSPHRASE
    if [ -z "$SSL_PASSPHRASE" ]
    then
      # read -rp "Name of SSL passphrase file NGINX ? [ Default: $SSL_PASSPHRASE_NGINX_CUSTOM_FILE ]: " -ei "$SSL_PASSPHRASE_NGINX_CUSTOM_FILE"  SSL_PASSPHRASE_NGINX_CUSTOM_FILE
      info "We search the NGINX and Apache2 files in $PWD/config/ssl/"
      info "NGINX File: $SSL_PASSPHRASE_NGINX_CUSTOM_FILE"
      command echo
    fi
    ;;
  *)
    info "We disabled the SSL passphrase capabilites. (Default)"
    ;;
  esac
}

#
# END Build Configuration
#
