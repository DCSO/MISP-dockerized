#!/bin/bash
set -eu

# check if user has currently a installed version
    # This function checks the current version on misp-server version from docker ps
    # https://forums.docker.com/t/docker-ps-a-command-to-publish-only-container-names/8483/2
    CURRENT_CONTAINER="$(docker ps --format '{{.Image}}'|grep misp-dockerized-server|cut -d : -f 2|cut -d - -f 1)"
    [ -z "$CURRENT_CONTAINER" ] && echo "Sorry, no Upgrade is possible. The reason is there is no running misp-server. I exit now." && docker ps && exit

##################      MAIN        #########################


# If the UPGRADE_STEP_1 File exists then check if the 'current' directory exists
if [ ! -f UPGRADE_STEP_1 ]
then
    # [1] Check if a current directory exists
    if [ ! -L ./current ]
    then
        EARLIER_1_0_0=no
        echo "no 'current' directory exists an direct upgrade is not possible."
        read -rp "Do you upgrade from an version earlier than 1.0.0? [DEFAULT: $EARLIER_1_0_0]: " -ei $EARLIER_1_0_0  EARLIER_1_0_0
        [ "$EARLIER_1_0_0" == "no" ] && echo "There is a bug, please open a ticket on https://github.com/DCSO/MISP-dockerized/issues and report the Error. Now i will exit." && exit
        [ "$EARLIER_1_0_0" == "yes" ] && echo "An Upgrade from an earlier version than 0.3.4 requires manual steps. See at https://dcso.github.io/MISP-dockerized-docs/ in the upgrade section"
    fi
 


    # [2] make a backup
    # echo "#############################################################################"
    # echo "Please Backup your full server and your storage for all critical MISP data!!!"
    # echo "If the backup is already done press enter now"
    # echo "#############################################################################"
    # read -r
    echo "We do now a full backup, this can be take a long time...." && sleep 2
    make -C current/ backup-all
    
    # Update Git repository
    if [ -n "$(command -v git)" ]
    then
        echo "Update git repository ..." && git pull
        touch UPGRADE_STEP_1
        echo "I start again..." && ./UPGRADE.sh
    else
        echo "No Git is available please download the Master Zip file from Github.com and make a manual upgrade."
        echo "wget https://github.com/DCSO/MISP-dockerized/archive/master.zip"
        exit 1
    fi

# if the UPGRADE_STEP_1 file exists go to else
else
    # [3] choose a new version
    ./FOR_NEW_INSTALL.sh
    make -C current install
    # Check if misp-db container exists and then upgrade it
    # shellcheck disable=SC2143
    if [ "$( grep DB_HOST config/config.env|cut -d = -f 2 )" = "misp-db" ];then
        docker exec -ti misp-db mysql_upgrade
        docker restart misp-db
    elif [ "$( grep DB_HOST config/config.env|cut -d = -f 2 )" = "localhost" ];then
        docker exec -ti misp-server mysql_upgrade
        docker restart misp-server
    fi

    # check if directory exists
    [ ! -d current ] && echo "There is a bug, please open a ticket on https://github.com/DCSO/MISP-dockerized/issues and report the error. Exit now." && exit
    
    echo "--- Done Upgrading ---"
    echo "If something is missing or there are problems with the login, please manually execute the function *make restore* from the MISP-dockerized base directory to restore the saved data."
    # Restore Data - normaly not needed
    #OPTION=""
    #while [ ! "$OPTION" = "exit" ]
    #do
    #    read -r -p "Which component volumes you want to restore? [ server | proxy | database | all OR exit ]: " -ei "$OPTION" OPTION
    #    
    #   case $OPTION in
    #    [aA][lL][lL])
    #        make -C current/ restore-all
    #        break
    #        ;;
    #    [sS][eE][rR][vV][eE][rR])
    #        make -C current/ restore-server
    #        break
    #        ;;
    #    [pP][rR][oO][xX][yY])
    #        make -C current/ restore-server
    #        break
    #        ;;
    #    [dD][aA][tT][aA][bB][aA][sS][eE])
    #        make -C current/ restore-server
    #        break
    #        ;;
    #    [eE][xX][iI][tT])
    #        OPTION="exit"
    #        break;
    #        ;;
    #    *)
    #        echo -e "\nplease choose only options from the text below!\n"
    #    ;;
    #    esac
    #done
    
    echo "Delete old unused files:"
    for i in .env UPGRADE_STEP_1 docker-compose.*
    do
        [ -f "$i" ] && rm -rfv "$i"
    done

fi