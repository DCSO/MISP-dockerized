#/bin/bash
#description     :This script remove all misp docker container, their volumes and the /opt/misp path.
#==============================================================================

echo "This will remove all <none> tagged images."
read -p "Are you sure? (y)" USER_GO
if [ "$USER_GO" == "y" ]; then
    echo '### remove MISP images ###'
    docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
fi
