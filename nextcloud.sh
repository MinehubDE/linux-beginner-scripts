#!/bin/bash

printf "\033c"

if [ "$(id -u)" != "0" ]; then
        echo -e "\n---------------------------------------------------------------------------------\n"
        echo -e "PLEASE EXECUTE THIS SCRIPT AS ROOT OR SUDO!\n"
        echo "sudo ${0}"
        echo -e "\n---------------------------------------------------------------------------------"
        exit 1
fi

echo "--------------------------------------------------"
echo "Welcome to the installation of Nextcloud on your server!"
echo "This script will install and configure a lot of dependencies and does not care about anything already installed on this system."
echo "Please consider NOT using this script if you have already installed one of the following applications:"
echo -e "\n- MySQL/MariaDB\n- PHP/PHP-FPM\n- Apache2/NGINX\n"
echo -e "--------------------------------------------------\n"

read -r -p "By typing YES the installation will start: " ANSWER

if [ "$ANSWER" != "YES" ]; then
        echo "YES was not entered. Will exit now"
        exit 1
else
	echo -e "\nInstallation will start shortly....\n"
	sleep 3
fi

# prerequisites
echo "--------------------------------------------------"
echo "Installing prerequisites"
echo "--------------------------------------------------"
apt-get update && apt-get install -y bzip2 host mariadb-server nginx-light pwgen openssl sudo

# generate certs
echo "--------------------------------------------------"
echo "Generating SSL certificates"
echo "--------------------------------------------------"
if [ ! -f /etc/ssl/nextcloud.key ]; then
	openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/nextcloud.key -out /etc/ssl/nextcloud.pem -days 365 -subj "/C=AN/ST=ANON/L=ANON/O=ANON/OU=ANON/CN=ANON/emailAddress=ANON"
else
	echo "Found existing certificate. Will skip creation of a new one."
fi

# download and extract latest Nextcloud version
echo "--------------------------------------------------"
echo "Downloading and installing Nextcloud"
echo "--------------------------------------------------"
wget -q -O - https://download.nextcloud.com/server/releases/latest.tar.bz2 | tar xfj - -C /var/www/
chown -R www-data:www-data /var/www/nextcloud

# install php-fpm with all modules
echo "--------------------------------------------------"
echo "Installing PHP-FPM and all needed modules"
echo "--------------------------------------------------"
apt-get install -y apt-transport-https gnupg2
wget -q -O - https://packages.sury.org/php/apt.gpg | apt-key add -
OS_VERSION=$(cat /etc/*-release | grep VERSION_CODENAME | sed 's/.*=//')
echo "deb https://packages.sury.org/php/ $OS_VERSION main" > /etc/apt/sources.list.d/php.list
apt-get update
apt-get install -y php-apcu php-bcmath php-curl php-fpm php-gd php-gmp php-imagick php-intl php-mbstring php-mysql php-xml php-zip

# configure nginx
echo "--------------------------------------------------"
echo "Configuring NGINX"
echo "--------------------------------------------------"
cp $(dirname $0)/nextcloud/nginx.conf /etc/nginx/sites-enabled/nextcloud.conf
IP=$(host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has address" | awk '{ print $NF }')
sed -i "s/PLACEHOLDER/$IP/g" /etc/nginx/sites-enabled/nextcloud.conf

# configure mariadb user and database
echo "--------------------------------------------------"
echo "Configuring MariaDB"
echo "--------------------------------------------------"
MYSQL_PW=$(pwgen -s 25 1)
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$MYSQL_PW') WHERE User = 'root'" &>/dev/null
mysql -e "DROP USER ''@'localhost'" &>/dev/null
mysql -e "DROP USER ''@'$(hostname)'" &>/dev/null
mysql -e "DROP DATABASE test" &>/dev/null
mysql -e "FLUSH PRIVILEGES" &>/dev/null
mysql -e "CREATE DATABASE nextclouddb" &>/dev/null
MYSQL_NC_PW=$(pwgen -s 32 1)
mysql -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$MYSQL_NC_PW'" &>/dev/null
mysql -e "GRANT ALL PRIVILEGES ON nextclouddb.* TO 'nextcloud'@'localhost'" &>/dev/null
mysql -e "FLUSH PRIVILEGES" &>/dev/null
systemctl restart mariadb

# configure PHP-FPM
echo "--------------------------------------------------"
echo "Configuring PHP-FPM"
echo "--------------------------------------------------"

PHP_FPM_CONF=$(find /etc/php/ -name "www.conf")
sed -i 's/^;env\[PATH\] =.*/env[PATH] = \/usr\/local\/bin:\/usr\/bin:\/bin\//' ${PHP_FPM_CONF}
PHP_FPM_INI=$(find /etc/php/*/fpm -name "php.ini")
sed -i 's/^memory_limit =.*/memory_limit = 512M/' ${PHP_FPM_INI}

# configure Nextcloud
echo "--------------------------------------------------"
echo "Configuring Nextcloud"
echo "--------------------------------------------------"
NC_ADMIN_PW=$(pwgen -s 25 1)
cd /var/www/nextcloud
sudo -u www-data php occ maintenance:install --database "mysql" --database-name "nextclouddb" --database-user "nextcloud" --database-pass "$MYSQL_NC_PW" --admin-user "admin" --admin-pass "$NC_ADMIN_PW"
sudo -u www-data php occ config:system:set trusted_domains 0 --value=${IP}
sudo -u www-data php occ config:system:set memcache.local --value=PLACEHOLDER
sed -i 's/PLACEHOLDER/\\OC\\Memcache\\APCu/' config/config.php

# restart php-fpm
echo "--------------------------------------------------"
echo "Restarting services"
echo "--------------------------------------------------"
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION; echo "."; echo PHP_MINOR_VERSION;')
systemctl restart php${PHP_VERSION}-fpm
# restart nginx
systemctl restart nginx

echo -e "\n--------------------------------------------------"
echo "--------------------------------------------------"
echo "--------------------------------------------------"
echo "NEXTCLOUD SUCCESSFULLY INSTALLED"
echo "--------------------------------------------------"
echo "--------------------------------------------------"
echo -e "--------------------------------------------------\n"

echo "Please save the following credentials. They are currently nowhere stored and will be lost once this screen disappears."

echo -e "\n--------------------------------------------------\n"
echo "DATABASE USER: nextcloud"
echo "DATABASE PASSWORD: $MYSQL_NC_PW"
echo -e "\n--------------------------------------------------\n"

echo -e "\n--------------------------------------------------\n"
echo "NEXTCLOUD WEB ENDPOINT: https://$IP/nextcloud"
echo "NEXTCLOUD USER: admin"
echo "NEXTCLOUD USER PASSWORD: $NC_ADMIN_PW"
echo -e "\n--------------------------------------------------"

