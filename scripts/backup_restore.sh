#!/bin/bash
#description     :This script can be used to backup and retore the misp docker environment.
#==============================================================================

if [[ ! ${1} =~ (backup|restore) ]]; then
  echo "First parameter needs to be 'backup' or 'restore'"
  exit 1
fi

if [[ ${1} == "backup" && ! ${2} =~ (server|redis|mysql|proxy|all) ]]; then
  echo "Second parameter needs to be 'server', 'redis', 'mysql', 'proxy' or 'all'"
  exit 1
fi

# set backup location as parameter
BACKUP_LOCATION="${3}"
# new default Backup Path:
[ -z $BACKUP_LOCATION ] && BACKUP_LOCATION="./backup"

# if [[ -z ${BACKUP_LOCATION} ]]; then
#   while [[ -z ${BACKUP_LOCATION} ]]; do
#     read -ep "Backup location (absolute path, starting with /): " BACKUP_LOCATION
#   done
# fi

if [[ ! ${BACKUP_LOCATION} =~ ^/ ]]; then
  echo "Backup directory needs to be given as absolute path (starting with /)."
  exit 1
fi

if [[ -f ${BACKUP_LOCATION} ]]; then
  echo "${BACKUP_LOCATION} is a file!"
  exit 1
fi

if [[ ! -d ${BACKUP_LOCATION} ]]; then
  echo "${BACKUP_LOCATION} is not a directory"
  read -p "Create it now? [y|N] " CREATE_BACKUP_LOCATION
  if [[ ! ${CREATE_BACKUP_LOCATION,,} =~ ^(yes|y)$ ]]; then
    exit 1
  else
    mkdir ${BACKUP_LOCATION}
    chmod 755 ${BACKUP_LOCATION}
  fi
else
  if [[ ${1} == "backup" ]] && [[ -z $(echo $(stat -Lc %a ${BACKUP_LOCATION}) | grep -oE '[0-9][0-9][5-7]') ]]; then
    echo "${BACKUP_LOCATION} is not write-able for others, that's required for a backup."
    exit 1
  fi
fi
BACKUP_LOCATION=$(echo ${BACKUP_LOCATION} | sed 's#/$##')
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPOSE_FILE=${SCRIPT_DIR}/../docker-compose.yml
source ${SCRIPT_DIR}/../.env

echo "Using ${BACKUP_LOCATION} as backup/restore location."
echo

## DebuggL
#echo "Script Dir:  ${SCRIPT_DIR}"
#echo "Compose File:  ${COMPOSE_FILE}"
#echo "MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}"


function backup() {
  DATE=$(date +"%Y-%m-%d-%H-%M-%S")
  mkdir -p "${BACKUP_LOCATION}/misp-${DATE}"
  chmod 755 "${BACKUP_LOCATION}/misp-${DATE}"
  while (( "$#" )); do
    case "$1" in
      server|all)
        echo "Backup server at ${BACKUP_LOCATION}/misp-${DATE}"
        docker run --rm \
          -v ${BACKUP_LOCATION}/misp-${DATE}:/backup \
          -v $(docker volume ls -qf name=misp-vol-server-data):/server \
          -v $(docker volume ls -qf name=misp-vol-server-logs):/logs \
          -v $(docker volume ls -qf name=misp-vol-server-config):/config \
          ubuntu:16.04 /bin/bash -c "tar -cvpzf /backup/backup_server_data.tar.gz /server; tar -cvpzf /backup/backup_server_logs.tar.gz /logs; tar -cvpzf /backup/backup_server_config.tar.gz /logs;"
      ;;&
      redis|all)
        echo "Backup redis at ${BACKUP_LOCATION}/misp-${DATE}"
        docker exec $(docker ps -qf name=misp-redis) redis-cli save
        docker run --rm \
          -v ${BACKUP_LOCATION}/misp-${DATE}:/backup \
          -v $(docker volume ls -qf name=misp-vol-redis-data):/redis \
          ubuntu:16.04 /bin/tar -cvpzf /backup/backup_redis.tar.gz /redis
      ;;&
      proxy|all)
        echo "Backup proxy at ${BACKUP_LOCATION}/misp-${DATE}"
        docker run --rm \
          -v ${BACKUP_LOCATION}/misp-${DATE}:/backup \
          -v $(docker volume ls -qf name=misp-vol-proxy-data):/data \
          -v $(docker volume ls -qf name=misp-vol-proxy-logs):/logs \
          ubuntu:16.04 /bin/bash -c "tar -cvpzf /backup/backup_proxy_data.tar.gz /data; tar -cvpzf /backup/backup_proxy_logs.tar.gz /logs;"
      ;;&
      mysql|all)
        echo "Backup mysql at ${BACKUP_LOCATION}/misp-${DATE}"
        #SQLIMAGE='mariadb:${DB_version}'
        SQLIMAGE='mariadb:10.3.5'
        docker run --rm \
          --network=$(docker network ls -qf name=misp) \
          -v ${BACKUP_LOCATION}/misp-${DATE}:/backup \
          ${SQLIMAGE} /bin/bash -c "mysqldump -u root -p${MYSQL_ROOT_PASSWORD} -h misp-db --all-databases | gzip > /backup/backup_mysql.gz"
      ;;&
      proxy|all)
        echo "Backup proxy at ${BACKUP_LOCATION}/misp-${DATE}"
        docker run --rm \
          -v ${BACKUP_LOCATION}/misp-${DATE}:/backup \
          -v $(docker volume ls -qf name=misp-vol-proxy-data):/data \
          -v $(docker volume ls -qf name=misp-vol-proxy-logs):/logs \
          ubuntu:16.04 /bin/bash -c "tar -cvpzf /backup/backup_proxy_data.tar.gz /data; tar -cvpzf /backup/backup_proxy_logs.tar.gz /logs;"
      ;;
    esac
    shift
  done
}

function restore() {
  RESTORE_LOCATION="${1}"
  shift
  while (( "$#" )); do
    case "$1" in    
      redis)
        echo "Restore MISP Redis" #Debug
        #docker stop $(docker ps -qf name=misp-redis)
        docker-compose stop misp-redis
        docker run -it --rm \
          -v ${RESTORE_LOCATION}:/backup \
          -v $(docker volume ls -qf name=misp-redis):/redis \
          ubuntu:16.04 /bin/tar -xvzf /backup/backup_redis.tar.gz
        #docker start $(docker ps -aqf name=misp-redis)
        docker-compose start misp-redis
      ;;
      mysql)
        echo "Restore MISP DB" #Debug
        #docker stop $(docker ps -qf name=misp-mysql)
        #docker-compose stop misp-db
        #SQLIMAGE=$(grep -iEo '(mysql|mariadb)\:.+' ${COMPOSE_FILE})
        SQLIMAGE='mariadb:10.3.5'
        docker run -it --rm \
          --network=$(docker network ls -qf name=misp) \
          -v ${RESTORE_LOCATION}:/backup \
          ${SQLIMAGE} /bin/bash -c "gunzip < /backup/backup_mysql.gz | cat > /backup/backup_mysql.sql; mysql -u root -p${MYSQL_ROOT_PASSWORD} -h misp-db < /backup/backup_mysql.sql; rm /backup/backup_mysql.sql;"
          #${SQLIMAGE} /bin/bash -c "gunzip < /backup/backup_mysql.gz | mysql -u root -p${DBROOT} -h misp-db"
        docker-compose restart misp-db
        #docker start $(docker ps -aqf name=misp-mysql)
        #docker-compose start misp-db
      ;;
      server)
        echo "Restore MISP Server" #Debug
        #docker stop $(docker ps -qf name=misp-server)
        docker-compose stop misp-server
        docker run -it --rm \
          -v ${RESTORE_LOCATION}:/backup \
          -v $(docker volume ls -qf name=server-data):/server \
          -v $(docker volume ls -qf name=server-log):/logs \
          -v $(docker volume ls -qf name=server-config):/config \
          ubuntu:16.04 /bin/sh -c "tar -xvzf /backup/backup_server_data.tar.gz; tar -xvzf /backup/backup_server_logs.tar.gz; tar -xvzf /backup/backup_server_config.tar.gz;"
        #docker start $(docker ps -aqf name=misp-server)
        docker-compose start misp-server
      ;;
      proxy)
        echo "Restore MISP Proxy" #Debug
        #docker stop $(docker ps -qf name=misp-proxy)
        docker-compose stop misp-proxy
        docker run -it --rm \
          -v ${RESTORE_LOCATION}:/backup \
          -v $(docker volume ls -qf name=proxy-data):/data \
          -v $(docker volume ls -qf name=proxy-log):/logs \
          ubuntu:16.04 /bin/sh -c "tar -xvzf /backup/backup_proxy_data.tar.gz; tar -xvzf /backup/backup_proxy_logs.tar.gz;"
        #docker start $(docker ps -aqf name=misp-proxy)
        docker-compose start misp-proxy
      ;;
    esac
    shift
  done
}

if [[ ${1} == "backup" ]]; then
  backup ${@,,}
elif [[ ${1} == "restore" ]]; then
  i=1
  declare -A FOLDER_SELECTION
  if [[ $(find ${BACKUP_LOCATION}/misp-* -maxdepth 1 -type d 2> /dev/null| wc -l) -lt 1 ]]; then
    echo "Selected backup location has no subfolders"
    exit 1
  fi
  for folder in $(ls -d ${BACKUP_LOCATION}/misp-*/); do
    echo "[ ${i} ] - ${folder}"
    FOLDER_SELECTION[${i}]="${folder}"
    ((i++))
  done
  echo
  input_sel=0
  while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
    read -p "Select a restore point: " input_sel
  done
  i=1
  echo
  declare -A FILE_SELECTION
  RESTORE_POINT="${FOLDER_SELECTION[${input_sel}]}"
  if [[ -z $(find "${FOLDER_SELECTION[${input_sel}]}" -maxdepth 1 -type f -regex ".*\(redis\|mysql\|server\).*") ]]; then
    echo "No datasets found"
    exit 1
  fi
  for file in $(ls -f "${FOLDER_SELECTION[${input_sel}]}"); do
    if [[ ${file} =~ server_data ]]; then
      echo "[ ${i} ] - Server directory"
      FILE_SELECTION[${i}]="server"
      ((i++))
    elif [[ ${file} =~ proxy_data ]]; then
      echo "[ ${i} ] - Proxy directory"
      FILE_SELECTION[${i}]="proxy"
      ((i++))
    elif [[ ${file} =~ redis ]]; then
      echo "[ ${i} ] - Redis DB"
      FILE_SELECTION[${i}]="redis"
      ((i++))
    elif [[ ${file} =~ mysql ]]; then
      echo "[ ${i} ] - SQL DB"
      FILE_SELECTION[${i}]="mysql"
      ((i++))
    fi
  done
  echo
  input_sel=0
  while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
    read -p "Select a dataset to restore: " input_sel
  done
  echo "Restoring ${FILE_SELECTION[${input_sel}]} from ${RESTORE_POINT}..."
  restore "${RESTORE_POINT}" ${FILE_SELECTION[${input_sel}]}
fi