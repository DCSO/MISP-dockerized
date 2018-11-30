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
#source ${SCRIPT_DIR}/../.env
source /srv/MISP-dockerized/config/config.env



## DebuggL
#echo "Script Dir:  ${SCRIPT_DIR}"
#echo "Compose File:  ${COMPOSE_FILE}"
#echo "MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}"
BACKUP_LOCATION="/srv/MISP-dockerized/backup"

function backup() {
  DATE=$(date +"%Y-%m-%d-%H-%M-%S")
  DOCKER_BACKUPDIR="${BACKUP_LOCATION}/misp-${DATE}"
  mkdir -p ${DOCKER_BACKUPDIR}
  chmod 755 ${DOCKER_BACKUPDIR}
  echo "--- Start Backup ---"
  while (( "$#" )); do
    case "$1" in
      server|all)
        echo "Backup server at ${DOCKER_BACKUPDIR}"
        tar -cvpzPf ${DOCKER_BACKUPDIR}/backup_server_data.tar.gz /srv/misp-server/MISP
        tar -cvpzPf ${DOCKER_BACKUPDIR}/backup_server_config.tar.gz /srv/misp-server/apache2
      ;;&
      redis|all)
        echo "Backup redis at ${DOCKER_BACKUPDIR}"
        docker exec $(docker ps -qf name=misp-server) redis-cli save
        tar -cvpzPf ${DOCKER_BACKUPDIR}/backup_redis.tar.gz /srv/misp-redis
      ;;&      
      proxy|all)
        echo "Backup proxy at ${DOCKER_BACKUPDIR}"
        tar -cvpzPf ${DOCKER_BACKUPDIR}/backup_proxy_data.tar.gz /srv/misp-proxy/conf.d
      ;;&
      mysql|all)
        echo "Backup mysql at ${DOCKER_BACKUPDIR} - This could take a while"
        mysqldump -u root -p${MYSQL_ROOT_PASSWORD} -h misp-server --all-databases | gzip > ${DOCKER_BACKUPDIR}/backup_mysql.gz & pid=$! 
        loading_animation ${pid}
      ;;#&
      #config|all)
      #  echo "Backup config files at ${DOCKER_BACKUPDIR}/misp-${DATE}"
      #  tar -cvpzf ${DOCKER_BACKUPDIR}/backup_config.tar.gz /srv/MISP-dockerized/config
      #;;
    esac
    shift
  done
  echo "--- Done ---"
}

function restore() {
  RESTORE_LOCATION="${1}"
  echo "--- Start Restore ---"
  # echo "Restore location: ${RESTORE_LOCATION}" # Debug Output
  shift
  while (( "$#" )); do
    case "$1" in    
      redis|all)
        echo "Restore MISP Redis" #Debug
        tar -xvzPf ${RESTORE_LOCATION}backup_redis.tar.gz
        docker exec misp-server service redis-server restart
      ;;&
      server|all)
        echo "Restore MISP Server" #Debug
        tar -xvzPf ${RESTORE_LOCATION}backup_server_data.tar.gz
        tar -xvzPf ${RESTORE_LOCATION}backup_server_config.tar.gz;
        docker exec misp-server service apache2 restart
      ;;&
      mysql|all)
        echo "Restore MISP DB - This could take a while" #Debug
        echo "-> unpacking .sql file"
        gunzip < ${RESTORE_LOCATION}backup_mysql.gz | cat > ${RESTORE_LOCATION}backup_mysql.sql & pid=$!
        loading_animation ${pid}
        echo "-> restore database"
        mysql -u root -p${MYSQL_ROOT_PASSWORD} -h misp-server < ${RESTORE_LOCATION}backup_mysql.sql & pid=$!
        loading_animation ${pid}
        echo "-> clean up"
        rm ${RESTORE_LOCATION}backup_mysql.sql    
        #echo "-> restarting MySQL"
        #docker exec misp-server service mysql restart
      ;;&
      proxy|all)
        echo "Restore MISP Proxy" #Debug
        tar -xvzPf ${RESTORE_LOCATION}backup_proxy_data.tar.gz
      ;;#&
      #config|all)
      #  echo "Restore config files"
      #  tar -xvzf ${BACKUP_LOCATION}/misp-${DATE}/backup_config.tar.gz -C ${SCRIPT_DIR}/../.
      #;;&
    esac
    shift
    echo "--- Done ---"
  done
}

function loading_animation() {
  pid=${1}

  spin='-\|/'

  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1} ...working"
    sleep .1
  done
  echo ""
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
    fi
    #elif [[ ${file} =~ config ]]; then
    #  echo "[ ${i} ] - Config files "
    #  FILE_SELECTION[${i}]="config"
    #  ((i++))    
  done
  echo "[ ${i} ] - All"
  FILE_SELECTION[${i}]="all"
  
  echo
  input_sel=0
  while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
    read -p "Select a dataset to restore: " input_sel
  done
  echo "Restoring ${FILE_SELECTION[${input_sel}]} from ${RESTORE_POINT}..."
  restore "${RESTORE_POINT}" ${FILE_SELECTION[${input_sel}]}
fi