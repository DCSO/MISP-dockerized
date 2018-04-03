#/bin/bash
#description     :This script install and start all misp docker container.
#==============================================================================
source /srv/scripts/functions.sh
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
docker_compose_file="docker-compose.yml"


# check if docker-compose is installed.
if [ -z "which docker-compose" ]
    then
        # no docker-compose exists exists
        echo -e "\n Sorry, i didn't found docker-compose please try to install it.
                 \n You can download it from: https://docs.docker.com/compose/install/ or from https://github.com/docker/compose/releases"
    else
        pushd $MISP_dockerized_repo
        if [ -f ".env" ] 
            then
                echo "configuration exists..."
            else
                echo ""
                echo "No config file available. Please do 'make build-config' first.\n\n"
                exit 1
        fi
        echo '...Starting Docker...'
        for container in misp-db misp-redis misp-server misp-proxy misp-robot
            do
                sudo docker-compose -f $docker_compose_file up -d $container
            done
        popd
fi
