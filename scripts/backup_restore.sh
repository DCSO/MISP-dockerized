#!/bin/bash
#description     :This script can be used to backup and retore the misp docker environment.
#==============================================================================

if [[ ! ${1} =~ (backup|restore) ]]; then
  echo "First parameter needs to be 'backup' or 'restore'"
  exit 1
fi

if [[ ${1} == "backup" && ! ${2} =~ (server|redis|mysql|proxy|config|all) ]]; then
  echo "Second parameter needs to be 'server', 'redis', 'mysql', 'proxy', 'config' or 'all'"
  exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPOSE_FILE=${SCRIPT_DIR}/../docker-compose.yml
source ${SCRIPT_DIR}/../.env



## DebuggL
#echo "Script Dir:  ${SCRIPT_DIR}"
#echo "Compose File:  ${COMPOSE_FILE}"
#echo "MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}"
BACKUP_LOCATION="/srv/misp-dockerized/backup"

function backup() {
  DATE=$(date +"%Y-%m-%d-%H-%M-%S")
  DOCKER_BACKUPDIR="${BACKUP_LOCATION}/misp-${DATE}"
  mkdir -p ${DOCKER_BACKUPDIR}
  chmod 755 ${DOCKER_BACKUPDIR}
  
  while (( "$#" )); do
    case "$1" in
      server|all)
        echo "Backup server at ${DOCKER_BACKUPDIR}/misp-${DATE}"
        tar -cvpzf ${DOCKER_BACKUPDIR}/backup_server_data.tar.gz /srv/misp-server/MISP
        tar -cvpzf ${DOCKER_BACKUPDIR}/backup_server_config.tar.gz /srv/misp-server/apache2
      ;;&
      redis|all)
        echo "Backup redis at ${DOCKER_BACKUPDIR}/misp-${DATE}"
        docker exec $(docker ps -qf name=misp-server) redis-cli save
        tar -cvpzf ${DOCKER_BACKUPDIR}/backup_redis.tar.gz /srv/misp-redis
      ;;&      
      proxy|all)
        echo "Backup proxy at ${DOCKER_BACKUPDIR}/misp-${DATE}"
        tar -cvpzf ${DOCKER_BACKUPDIR}/backup_proxy_data.tar.gz /srv/misp-proxy/conf.d
      ;;&
      mysql|all)
        echo "Backup mysql at ${DOCKER_BACKUPDIR}/misp-${DATE}"
        mysqldump -u root -p${MYSQL_ROOT_PASSWORD} -h misp-db --all-databases | gzip > ${DOCKER_BACKUPDIR}/backup_mysql.gz
      ;;#&
      #config|all)
      #  echo "Backup config files at ${DOCKER_BACKUPDIR}/misp-${DATE}"
      #  tar -cvpzf ${DOCKER_BACKUPDIR}/backup_config.tar.gz /srv/misp-dockerized/config
      #;;
    esac
    shift
  done
}

function restore() {
  RESTORE_LOCATION="${BACKUP_LOCATION}"
  shift
  while (( "$#" )); do
    case "$1" in    
      redis|all)
        echo "Restore MISP Redis" #Debug
        tar -xvzf /backup_redis.tar.gz
        docker exec misp-server service redis-server restart
      ;;&
      server|all)
        echo "Restore MISP Server" #Debug
        tar -xvzf /backup_server_data.tar.gz
        tar -xvzf /backup_server_config.tar.gz;
        docker exec misp-server service apache2 restart
      ;;&
      mysql|all)
        echo "Restore MISP DB" #Debug
        gunzip < /backup_mysql.gz | cat > /backup_mysql.sql
        mysql -u root -p${MYSQL_ROOT_PASSWORD} -h misp-db < /backup_mysql.sql
        rm /backup_mysql.sql        
      ;;&
      proxy|all)
        echo "Restore MISP Proxy" #Debug
        tar -xvzf /backup_proxy_data.tar.gz
      ;;#&
      #config|all)
      #  echo "Restore config files"
      #  tar -xvzf ${BACKUP_LOCATION}/misp-${DATE}/backup_config.tar.gz -C ${SCRIPT_DIR}/../.
      #;;&
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
    FOLDER_SELECTION[${i}]="${fold er}"
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
  if [[ -z $(find "${FOLDER_SELECTION[${input_sel}]}" -maxdepth 1 -type f -regex ".*\(redis\|mysql\|server\|config\).*") ]]; then
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
    elif [[ ${file} =~ config ]]; then
      echo "[ ${i} ] - Config files "
      FILE_SELECTION[${i}]="config"
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