#!/bin/bash
#description     :This script build the configuration for the MISP Container and their content.
#==============================================================================
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
###########################################
# Start Global Variabel Section
MISP_TAG=2.4.88
python_cybox_TAG=v2.1.0.12
python_stix_TAG=v1.1.1.4
mixbox_TAG=v1.0.2
cake_resque_TAG=4.1.2
REDIS_V=3.2.11
DB_V=10.3.5
DOCKER_COMPOSE_CONF="$SCRIPTPATH/../config/.env"
MISP_CONF_YML="$SCRIPTPATH/../config/misp.conf.yml"
############################################

# Start Function Section
function check_exists_configs(){
  # check config file and backup if its needed
  if [[ -f $DOCKER_COMPOSE_CONF ]]; then
    read -r -p "A docker-compose config file exists and will be overwritten, are you sure you want to contine? [y/N] " response
    case $response in
      [yY][eE][sS]|[yY])
        mv $DOCKER_COMPOSE_CONF $DOCKER_COMPOSE_CONF-backup_`date +%Y%m%d_%H_%M`
        ;;
      *)
        exit 1
      ;;
    esac
  fi
  # check config file and backup if its needed
  if [[ -f $MISP_CONF_YML ]]; then
    read -r -p "A misp config file exists and will be overwritten, are you sure you want to contine? [y/N] " response
    case $response in
      [yY][eE][sS]|[yY])
        mv $MISP_CONF_YML $MISP_CONF_YML-backup_`date +%Y%m%d_%H_%M`
        ;;
      *)
        exit 1
      ;;
    esac
  fi
}

function query_misp_tag(){
  # read MISP Tag for MISP Instance
  read -p "Which MISP Tag we should install[default: $MISP_TAG: " -ei "$MISP_TAG" MISP_TAG
}

function query_hostname(){
  # read Hostname for MISP Instance
  read -p "Hostname (FQDN - example.org is not a valid FQDN): " -ei "misp.example.com" HOSTNAME
}

function query_proxy(){
  # read Proxy Settings MISP Instance
  while (true)
  do
    read -r -p "Should we use http proxy? [y/N] " -ei "N" response
    case $response in
      [yY][eE][sS]|[yY])
        USE_PROXY=yes
        read -p "Which Proxy we should use (for example: http://proxy.example.com:80/) [default: none]: " -ei "" HTTP_PROXY
        read -p "For which site(s) we shouldn't use a Proxy (for example: localhost,127.0.0.0/8,docker-registry.somecorporation.com) [default: 0.0.0.0]: " -ei "0.0.0.0" NO_PROXY
        break
        ;;
      [nN][oO]|[nN])
        # do nothing
        USE_PROXY=no
        break
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
      read -r -p "Do you want to use an existing Database? [y/N] " -ei "N" response
      case $response in
        [yY][eE][sS]|[yY])
          OWN_DB=y
          read -p "Which DB Host should we use for DB Connection: " -ei "" MISP_host
          read -p "Which DB Port should we use for DB Connection [default: 3306]: " -ei "3306" MISP_port
          break;
          ;;
        [nN][oO]|[nN])
          OWN_DB=n
          # Set MISP_host to DB Container Name and Port
          MISP_host="misp-db"; echo "Set DB Host to docker default: $MISP_host"
          MISP_port=3306; echo "Set DB Host Port to docker default: $MISP_port"
          read -p "Which DB Root Password should we use for DB Connection [default: generated PW]: " -ei "$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" DBROOT
            while (true)
            do
              read -r -p "Should we allow empty Password? [y/N] " -ei "N" response
              case $response in
                [yY][eE][sS]|[yY])
                  DB_ALLOW_EMPTY_PW="MYSQL_ALLOW_EMPTY_PASSWORD:"
                  DB_CONTAINER_VERSION="$DB_V"
                  break;
                  ;;
                [nN][oO]|[nN])
                  # do nothing
                  break;
                  ;;
                *)
                  echo -e "\nplease only choose [y|n] for the question!\n"
                ;;
              esac
            done
            break;
          ;;
        *)
          echo -e "\nplease only choose [y|n] for the question!\n"
      esac
    done
  read -p "Which DB Name should we use for DB Connection [default: misp]: " -ei "misp" DBNAME
  read -p "Which DB User should we use for DB Connection [default: misp]: " -ei "misp" DBUSER
  read -p "Which DB User Password should we use for DB Connection [default: generated PW]: " -ei "$(</dev/urandom tr -dc A-Za-z0-9 | head -c 28)" DBPASS

}

function query_http_settings(){
  # read HTTP Settings
  read -p "Which HTTP Port should we expose [default: 80]: " -ei "80" HTTP_PORT
  read -p "Which HTTPS Port should we expose [default: 443]: " -ei "443" HTTPS_PORT
  read -p "Which HTTP Serveradmin mailadress should we use [default: admin@${HOSTNAME}]: " -ei "admin@${HOSTNAME}" HTTP_SERVERADMIN
          while (true)
          do
            read -r -p "Should we allow access to misp from every IP? [y/N]" -ei "N" response
            case $response in
              [yY][eE][sS]|[yY])
                # do nothing
                break
                ;;
              [nN][oO]|[nN])
                read -p "Which IPs should have access? [default: 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8]: " -ei "192.168.0.0/16 172.16.0.0/12 10.0.0.0/8" HTTP_ALLOWED_IP
                break
                ;;
              *)
                echo -e "\nplease only choose [y|n] for the question!\n"
              ;;
            esac
          done
}

function query_misp_settings(){
  # read and set MISP config settings
  #read -p "Which MISP login should we use [default: misp]: " -ei "misp" MISP_login
  MISP_login=admin@admin.test
  #read -p "Which MISP DB prefix should we use [default: '']: " -ei "" MISP_prefix
  MISP_prefix=""
  #read -p "Which MISP Encoding should we use [default: utf8]: " -ei "utf8" 
  MISP_encoding="utf8"
}

#################################################
# Start Execution:
check_exists_configs
query_misp_tag
query_hostname
query_proxy
query_db_settings
query_http_settings
query_misp_settings

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
  # Proxy Configuration
  # ------------------------------
  HTTP_PROXY=${HTTP_PROXY}
  NO_PROXY=${NO_PROXY}
  USE_PROXY=${USE_PROXY}
  # ------------------------------
  # DB configuration
  # ------------------------------
  DB_VERSION=${DB_V}
  MYSQL_DATABASE=${DBNAME}
  MYSQL_USER=${DBUSER}
  MYSQL_PASSWORD=${DBPASS}
  MYSQL_ROOT_PASSWORD=${DBROOT}
  ${DB_ALLOW_EMPTY_PW}
  # ------------------------------
  # HTTP/S configuration
  # ------------------------------
  HTTP_PORT=${HTTP_PORT}
  HTTPS_PORT=${HTTPS_PORT}
  HTTP_SERVERADMIN=${HTTP_SERVERADMIN}
  # ------------------------------
  # Redis configuration
  # ------------------------------
  REDIS_VERSION=${REDIS_V}
  # ------------------------------
  # misp-server env configuration
  # ------------------------------
  MISP_TAG=${MISP_TAG}
  python_cybox_TAG=${python_cybox_TAG}
  python_stix_TAG=${python_stix_TAG}
  mixbox_TAG=${mixbox_TAG}
  cake_resque_TAG=${cake_resque_TAG}
  ##################################################################
EOF
 
cat << EOF > $MISP_CONF_YML
#description     :This Config sets the MISP Config
#=================================================
#
# MISP
#
# ------------------------------
# MISP database configuration
# ------------------------------
MYSQL_ROOT_PASSWORD: ${DBROOT}
MISP_db_host: ${MISP_host}
MISP_db_login: ${MISP_login}
MISP_db_port: ${MISP_port}
MISP_db_password: ${DBPASS}
MISP_db_name: ${DBNAME}
# ------------------------------
# MISP server configuration
# ------------------------------
MISP_hostname: ${HOSTNAME}
MISP_hostport: ${HTTPS_PORT}
# ------------------------------
# MISP redis configuration
# ------------------------------
REDIS_hostname: misp-redis
REDIS_passwort:
REDIS_port:
# ------------------------------
# MISP NGINX configuration
# ------------------------------
client_max_body_size: "client_max_body_size 50M"
HTTP_ALLOWED_IP: "${HTTP_ALLOWED_IP}"
# ------------------------------
# Proxy Configuration
# ------------------------------
HTTP_PROXY: "${HTTP_PROXY}"
NO_PROXY: "${NO_PROXY}"
USE_PROXY: "${USE_PROXY}"
EOF
# link .env to the docker-compose file
[ -e "$SCRIPTPATH/../.env" ] || ln -s $DOCKER_COMPOSE_CONF $SCRIPTPATH/../.env
