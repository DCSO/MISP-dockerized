#!/bin/bash

function upgrade_to_1.0.0(){
    echo "Upgrade from Version before 1.0.0"
    # if current folder not exists execute install.sh script
    [ -L ./current ] || ./install.sh

    # move old files into the current folder
    FOLDER="./current/"
    mv .env $FOLDER
    mv Makefile $FOLDER

}
