#!/bin/sh
set -eu

# If you want to restore first install environment
  if [ "${1-}" = "restore" ]; then
    echo "Install standard deployment ..."
    make install && sleep 2
  fi

# Start script
  echo "Start backup_restore script ..."
  docker exec -ti misp-robot sh -c "/srv/scripts/backup_restore.sh $*"
