#!/bin/sh
set -vx

GIT_FOLDER="MISP-dockerized-testbench"
HOSTNAME=$(cat ../docker-compose.override.yml |grep HOSTNAME |cut -d : -f 2|cut -d " " -f 2|head -1)



# install dependencies for ALPINE!!!
if [ ! -z "$(which apk)"  ]
then
    # apk is avaialable (mostly alpine)
    [ -z $(which git) ] && echo "add git..." && apk add --no-cache git 
    [ -z $(which bash) ] && echo "add bash..." && apk add --no-cache bash
    [ -z $(which make) ] && echo "add make..." && apk add --no-cache make 
    [ -z $(which sudo) ] && echo "add sudo..." && apk add --no-cache sudo 
    [ -z $(which python3) ] && echo "add python3..." && apk add --no-cache python3 
    [ -z $(which mysql) ] && echo "add python3..." && apk add --no-cache mysql-client 
    echo
elif [ ! -z "$(which apt-get)"  ]
then
    # apt-get is available (mostly debian or ubuntu)
    sudo apt-get update
    [ -z $(which sudo) ] && echo "add sudo..." && apt-get -y install sudo
    [ -z $(which git) ] && echo "add git..." && sudo apt-get -y install git 
    [ -z $(which bash) ] && echo "add bash..." && sudo apt-get -y install bash
    [ -z $(which make) ] && echo "add make..." && sudo apt-get -y install make 
    #[ -z $(which python3) ] && 
    echo "add python3..." && sudo apt-get -y install python3 
    #[ -z $(which pip3) ] && 
    echo "add python3-pip..." && sudo apt-get -y install python3-pip 
    [ -z $(which mysql) ] && echo "add python3..." && sudo apt-get -y install  mysql-client
    echo "add python3-venv..." && sudo apt-get -y install python3-venv 
    
    echo "autoremove..." && sudo apt-get -y autoremove; 
    echo "clean..." && sudo apt-get -y clean
    echo
fi

# clone the repository
git clone https://github.com/DCSO/MISP-dockerized-testbench.git $GIT_FOLDER

cd  $GIT_FOLDER

# install python requirements
python3 -m venv venv
source venv/bin/activate
echo "pip3 install --no-cache-dir -r requirements.txt" && pip3 install --no-cache-dir -r requirements.txt

# generate report folder
[ -d reports ] || mkdir reports

# Init MISP and create user
sleep 90
while true
do
    # check status of misp-server
    docker logs --tail 10 misp-server
    
    # copy auth_key
    export AUTH_KEY=$(docker exec misp-server bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "SELECT authkey FROM users;" | head -2|tail -1')
    
    # initial user if all is good auth_key is return
    [ -z $AUTH_KEY  ] && export AUTH_KEY=$(docker exec misp-server bash -c "sudo -E /var/www/MISP/app/Console/cake userInit -q") && echo "new Auth_Key: $AUTH_KEY"
    
    # if user is initalized but mysql is not ready continue
    [ "$AUTH_KEY" == "Script aborted: MISP instance already initialised." ] && continue
    
    # if the auth_key is save go out 
    [ -z $AUTH_KEY ] || break
    
    # check status of misp-server
    docker logs --tail 10 misp-server
    
    
    # wait 5 seconds
    sleep 5
done


# generate settings.json
cat << EOF > settings.json
{
    "verify_cert": "False",
    "url": "https://${HOSTNAME}",
    "authkey": "${AUTH_KEY}",
    "basic_user": "admin@admin.test",
    "basic_password": "admin",
    "password": "ChangeMe123456!"
}

EOF
cat settings.json



echo "Add $HOSTNAME to 127.0.0.1 in /etc/hosts" && sudo echo "127.0.0.1 $HOSTNAME" >> /etc/hosts




# Run Tests
echo "python3 misp-testbench.py " && python3 misp-testbench.py 
