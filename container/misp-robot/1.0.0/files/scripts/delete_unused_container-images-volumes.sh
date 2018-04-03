#/bin/bash
#description     :This script remove all misp docker container, their volumes and the /opt/misp path.
#==============================================================================

echo "This will remove all unused images, volumes and container."
read -p "Are you sure? (y)" USER_GO
if [ "$USER_GO" == "y" ]; then
    echo '### remove unused container ###'
    docker container prune
    echo '### remove unused volumes ###'
    docker volume prune
    echo '### remove unused images ###'
    docker image prune
    echo '### remove unused networks ###'
    docker network prune
fi
