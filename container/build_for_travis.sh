#!/bin/bash

function build_container(){
    CONTAINER="$1"
    pushd ./container/$CONTAINER
    for i in $(ls -d */|sed 's/.$//')
    do
        echo -e "\n###################################################\n  #  build $CONTAINER with version $i...\n###################################################\n"
        ./build.sh $i
        echo -e "###################################################\n  #  build $CONTAINER with version $i...finished\n###################################################\n"
    done
    popd
}

while (($#)); do
  case "${1}" in
    misp-proxy)
        build_container misp-proxy
        exit 0
    ;;
    misp-server)
        build_container misp-server
        exit 0
    ;;
    misp-robot)
        build_container misp-robot
        exit 0
    ;;
    *)
        exit 1
  esac
done
