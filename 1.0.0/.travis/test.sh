#!/bin/sh

GIT_FOLDER="MISP-dockerized-testbench"

# install dependencies for ALPINE!!!
[ -z $(which git) ] && apk add --no-cache git 
[ -z $(which bash) ] && apk add --no-cache bash
[ -z $(which make) ] && apk add --no-cache make 
[ -z $(which sudo) ] && apk add --no-cache sudo 

# clone the repository
git clone https://github.com/DCSO/MISP-dockerized-testbench.git $GIT_FOLDER

# install python requirements
python3 -m venv venv
source venv/bin/activate
pip3 install --no-cache-dir -r $GIT_FOLDER/requirements.txt


# generate report folder
[ -d reports ] || mkdir reports


# Init MISP and create user
[ -z $AUTH_KEY ] && export AUTH_KEY=docker exec misp-server bash -c 'sudo -E /var/www/MISP/app/Console/cake userInit -q'



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