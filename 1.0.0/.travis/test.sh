#!/bin/sh

GIT_FOLDER="MISP-dockerized-testbench"

# install dependencies for ALPINE!!!
if [ ! -z "$(which apk)"  ]
then
    # apk is avaialable (mostly alpine)
    [ -z $(which git) ] && apk add --no-cache git 
    [ -z $(which bash) ] && apk add --no-cache bash
    [ -z $(which make) ] && apk add --no-cache make 
    [ -z $(which sudo) ] && apk add --no-cache sudo 
    echo
elif [ ! -z "$(which apt-get)"  ]
then
    # apt-get is available (mostly debian or ubuntu)
    sudo apt-get update
    [ -z $(which sudo) ] && apt-get -y install sudo
    [ -z $(which git) ] && sudo apt-get -y install git 
    [ -z $(which bash) ] && sudo apt-get -y install bash
    [ -z $(which make) ] && sudo apt-get -y install make 
    [ -z $(which python3) ] && sudo apt-get -y install python3 
    [ -z $(which pip3) ] && sudo apt-get -y install python3-pip 
    
    sudo apt-get -y install python3-venv 
    sudo apt-get autoremove; sudo apt-get clean
    echo
fi

# clone the repository
git clone https://github.com/DCSO/MISP-dockerized-testbench.git $GIT_FOLDER

# install python requirements
#python3 -m venv venv
#source venv/bin/activate
pip3 install --no-cache-dir -r $GIT_FOLDER/requirements.txt


# generate report folder
[ -d reports ] || mkdir reports


# Init MISP and create user
[ -z $AUTH_KEY ] && export AUTH_KEY="$(docker exec misp-server bash -c 'sudo -E /var/www/MISP/app/Console/cake userInit -q')"



# generate settings.json
cat << EOF > settings.json
{
    "verify_cert": "False",
    "url": "https://172.17.0.1",
    "authkey": "${AUTH_KEY}",
    "basic_user": "admin@admin.test",
    "basic_password": "admin",
    "password": "ChangeMe123456!"
}

EOF

# Run Tests
python3 $GIT_FOLDER/misp-testbench.py 