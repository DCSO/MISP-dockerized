#!/bin/bash

#examples:
#lint .travis.yml

#   travis cli
function check_via_travis_cli(){
    docker run -ti -v $(pwd):/project --rm skandyla/travis-cli "$1" "$2" $3
}

while (($#)); do
  case "${1}" in
    check)
        check_via_travis_cli lint .travis.yml
        exit 0
    ;;
    encrypt)
        [ -z $2 ] && [ -z $3 ] && echo -e "Please use the command as followed:\n$@ <VAR NAME> <VALUE>" && exit 1
        check_via_travis_cli encrypt "$2=$3" "$4"
        exit 0
    ;;
    *)
        exit 1
  esac
done