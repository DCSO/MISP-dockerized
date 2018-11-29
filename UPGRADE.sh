#!/bin/bash

function upgrade_to_1.0.0(){
    echo "Upgrade from Version before 1.0.0"
    # if current folder not exists execute install.sh script
    [ -L ./current ] || ./FOR_NEW_INSTALL.sh

    # move old files into the current folder
    FOLDER="./current/"
    mv .env $FOLDER
    mv Makefile $FOLDER

}







if [ ! -f UPGRADE_STEP_1 ]
then
    # [1] Check if a current directory exists
    if [ ! -d current ]
    then
        EARLIER_1_0_0=no
        echo "no 'current' directory exists an direct upgrade is not possible."
        read -p "Do you upgrade from an version earlier than 1.0.0? [DEFAULT: $EARLIER_1_0_0]: " -ei $EARLIER_1_0_0  EARLIER_1_0_0
        [ $EARLIER_1_0_0 == "no"] && echo "There is a bug, please open a ticket on https://github.com/DCSO/MISP-dockerized/issues and report the Error. Now i will exit." && exit
    fi

    # [2] make a backup
    echo "We do now a full backup, this can be take a long time."
    make -C current/ backup-all
    
    # [3] choose a new version
    touch UPGRADE_STEP_1
    FOR_NEW_INSTALL.sh
else
    # check if directory exists
    [ ! -d current ] && echo "There is a bug, please open a ticket on https://github.com/DCSO/MISP-dockerized/issues and report the Error. Now i will exit." && exit
    
    # Restore Data
    OPTION=""
    while ( [ ! "$OPTION" == "exit" ] )
    do
        read -r -p "Which component volumes you want to restore? [ server | proxy | database | all OR exit ]: " -ei "$OPTION" OPTION
        
        case $OPTION in
        [aA][lL][lL])
            make -C current/ restore-all
            break
            ;;
        [sS][eE][rR][vV][eE][rR])
            make -C current/ restore-server
            break
            ;;
        [pP][rR][oO][xX][yY])
            make -C current/ restore-server
            break
            ;;
        [dD][aA][tT][aA][bB][aA][sS][eE])
            make -C current/ restore-server
            break
            ;;
        [eE][xX][iI][tT])
            OPTION=exit
            break;
            ;;
        *)
            echo -e "\nplease choose only options from the text below!\n"
        ;;
        esac
    done
    

fi