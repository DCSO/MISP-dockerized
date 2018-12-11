#!/bin/sh
set -vx

GIT_FOLDER="MISP-dockerized-testbench"

# install dependencies for ALPINE!!!
if [ ! -z "$(which apk)"  ]
then
    # apk is avaialable (mostly alpine)
    [ -z $(which git) ] && echo "add git..." && apk add --no-cache git 
    [ -z $(which bash) ] && echo "add bash..." && apk add --no-cache bash
    [ -z $(which make) ] && echo "add make..." && apk add --no-cache make 
    [ -z $(which sudo) ] && echo "add sudo..." && apk add --no-cache sudo 
    echo
elif [ ! -z "$(which apt-get)"  ]
then
    # apt-get is available (mostly debian or ubuntu)
    sudo apt-get update
    [ -z $(which sudo) ] && echo "add sudo..." && apt-get -y install sudo
    [ -z $(which git) ] && echo "add git..." && sudo apt-get -y install git 
    [ -z $(which bash) ] && echo "add bash..." && sudo apt-get -y install bash
    [ -z $(which make) ] && echo "add make..." && sudo apt-get -y install make 
    [ -z $(which python3) ] && echo "add python3..." && sudo apt-get -y install python3 
    [ -z $(which pip3) ] && echo "add python3-pip..." && sudo apt-get -y install python3-pip 
    
    echo "add python3-venv..." && sudo apt-get -y install python3-venv 
    echo "autoremove..." && sudo apt-get autoremove; 
    echo "clean..." && sudo apt-get clean
    echo
fi

# clone the repository
git clone https://github.com/DCSO/MISP-dockerized-testbench.git $GIT_FOLDER

docker ps

# install python requirements
#python3 -m venv venv
#source venv/bin/activate
echo "pip3 install --no-cache-dir -r $GIT_FOLDER/requirements.txt" && pip3 install --no-cache-dir -r $GIT_FOLDER/requirements.txt

# generate report foldergit clone htgit clone https://github.com/DCSO/MISP-dockerized-testbench.git $GIT_FOLDERtps://github.com/DCSO/MISP-dockerized-testbench.git $GIT_FOLDER
[ -d reports ] || mkdir reports

# Init MISP and create user
    docker ps -a
    sleep 60
    docker ps -a
[ -z $AUTH_KEY ] && export AUTH_KEY=$(docker exec misp-server bash -c "sudo -E /var/www/MISP/app/Console/cake userInit -q") && echo "new Auth_Key: $AUTH_KEY"


# generate settings.json
cat << EOF > settings.json
{
    "verify_cert": "False",
    "url": "https://localhost",
    "authkey": "${AUTH_KEY}",
    "basic_user": "admin@admin.test",
    "basic_password": "admin",
    "password": "ChangeMe123456!"
}

EOF

echo "cat settings.json..." && cat settings.json

# Run Tests
echo "python3 $GIT_FOLDER/misp-testbench.py " && python3 $GIT_FOLDER/misp-testbench.py 