#/bin/bash


VOLUME_FOLDER="/volume"

function move_and_link(){
    mv $1 $2
    ln -s $2 $1
}

####################    MAIN    #############################

# Create Volume Folder
mkdir $VOLUME_FOLDER
chown www-data:www-data $VOLUME_FOLDER \

# MISP Config
move_and_link /var/www/MISP/app/Config $VOLUME_FOLDER/MISP-app-Config
# MISP TMP
move_and_link /var/www/MISP/app/tmp $VOLUME_FOLDER/MISP-app-tmp
# MISP Attachments
move_and_link /var/www/MISP/app/files $VOLUME_FOLDER/MISP-app-files
# 
move_and_link /var/www/MISP/app/Plugin/CakeResque/Config/config.php $VOLUME_FOLDER/CakeResque-config.php


# APACHE2 Configuration
move_and_link /etc/apache2/sites-available $VOLUME_FOLDER/apache2-sites-available
move_and_link /etc/apache2/ports.conf $VOLUME_FOLDER/apache2-ports.conf
# PHP
move_and_link /etc/php/7.0/apache2/php.ini $VOLUME_FOLDER/php7.0-apache2.php.ini


# LOGGING
move_and_link /var/log/apache2/ $VOLUME_FOLDER/log-apache2

# remove Script
rm -f $0