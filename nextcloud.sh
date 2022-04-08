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
apt-get update && apt-get install -y bzip2 host mariadb-server nginx-light pwgen openssl sudo wget

# generate certs
echo "--------------------------------------------------"
echo "Generating SSL certificates"
echo "--------------------------------------------------"
CERT=0
while [[ $CERT == 0 ]]; do
	read -r -p "Do you own a domain that points on this server? [yes/no]: " DOMAIN
	case $DOMAIN in
		YES|yes|y)
			read -r -p "Please enter the domain name, e.g. blubb.example.com: " DOMAIN_FQDN
			apt-get -y install certbot
			kill -9 $(lsof -i :80 | grep "LISTEN" | awk '{ print $2 }') 2>/dev/null
			certbot certonly --standalone -d "$DOMAIN_FQDN" --non-interactive --agree-tos -m "webmaster@$DOMAIN_FQDN"
			if [[ $? -eq 0 ]]; then
				CERT_PATH="/etc/letsencrypt/live/$DOMAIN_FQDN/fullchain.pem"
				CERT_KEY_PATH="/etc/letsencrypt/live/$DOMAIN_FQDN/privkey.pem"
				CERT=1
			else
				exit $?
			fi
		;;
		NO|no|n)
			CERT_PATH=/etc/ssl/nextcloud.pem
			CERT_KEY_PATH=/etc/ssl/nextcloud.key
			if [ ! -f "$CERT_KEY_PATH" ]; then
				openssl req -x509 -nodes -newkey rsa:4096 -keyout "$CERT_KEY_PATH" -out "$CERT_PATH" -days 365 -subj "/C=AN/ST=ANON/L=ANON/O=ANON/OU=ANON/CN=ANON/emailAddress=ANON"
			else
				echo "Found existing certificate. Will skip creation of a new one."
			fi
			CERT=1
		;;
		*)
			echo 'No valid input was given. If you do not own a domain, please type "no" without quotes.'
		;;
	esac
done

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
# Force PHP 8 from website
TEMP_PHP_VERS=$(curl -s https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html | grep PHP | grep recommended | grep strong | sed 's/.*<strong>//g' | sed 's/<\/strong>.*//g')
apt-get -y install php${TEMP_PHP_VERS}-fpm
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION; echo "."; echo PHP_MINOR_VERSION;')
apt-get install -y php${PHP_VERSION}-apcu php${PHP_VERSION}-bcmath php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-gmp php${PHP_VERSION}-imagick php${PHP_VERSION}-intl php${PHP_VERSION}-mbstring php${PHP_VERSION}-mysql php${PHP_VERSION}-xml php${PHP_VERSION}-zip libmagickcore-6.q16-6-extra

# configure nginx
echo "--------------------------------------------------"
echo "Configuring NGINX"
echo "--------------------------------------------------"
cp $(dirname $0)/nextcloud/nginx.conf /etc/nginx/sites-enabled/nextcloud.conf
sed -i "s~CERT_PATH_PLACEHOLDER~$CERT_PATH~g" /etc/nginx/sites-enabled/nextcloud.conf
sed -i "s~CERT_KEY_PATH_PLACEHOLDER~$CERT_KEY_PATH~g" /etc/nginx/sites-enabled/nextcloud.conf
if [ -z $DOMAIN_FQDN ]; then
	IP=$(ip r get $(ip r | grep "default via" | sed 's/.*via //' | sed 's/ dev.*//') | head -1 | sed 's/.*src //' | sed 's/ .*//')
else
	sed -i '/add_header X-XSS-Protection.*/a\        add_header Strict-Transport-Security "max-age=15768000; preload;" always;' /etc/nginx/sites-enabled/nextcloud.conf
	IP="$DOMAIN_FQDN"
fi
sed -i "s/IP_PLACEHOLDER/$IP/g" /etc/nginx/sites-enabled/nextcloud.conf
sed -i "s/\[PHP_PLACEHOLDER\]/$PHP_VERSION/g" /etc/nginx/sites-enabled/nextcloud.conf

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
grep -q "apc.enable_cli=1" "/etc/php/$PHP_VERSION/cli/php.ini" || echo "apc.enable_cli=1" >> "/etc/php/$PHP_VERSION/cli/php.ini"

# configure Nextcloud
echo "--------------------------------------------------"
echo "Configuring Nextcloud"
echo "--------------------------------------------------"
NC_ADMIN_PW=$(pwgen -s 25 1)
cd /var/www/nextcloud
sudo -u www-data php occ maintenance:install --database "mysql" --database-name "nextclouddb" --database-user "nextcloud" --database-pass "$MYSQL_NC_PW" --admin-user "admin" --admin-pass "$NC_ADMIN_PW"
sudo -u www-data php occ config:system:set trusted_domains 0 --value=${IP}
sudo -u www-data php occ config:system:set memcache.local --value=MEM_PLACEHOLDER
sed -i 's/MEM_PLACEHOLDER/\\OC\\Memcache\\APCu/' config/config.php
sudo -u www-data php occ config:system:set default_phone_region --value=DE

# restart php-fpm
echo "--------------------------------------------------"
echo "Restarting services"
echo "--------------------------------------------------"
systemctl restart php${PHP_VERSION}-fpm
# restart nginx
systemctl restart nginx

function final_echo {
echo -e "\n--------------------------------------------------"
echo "--------------------------------------------------"
echo "--------------------------------------------------"
echo "NEXTCLOUD SUCCESSFULLY INSTALLED"
echo "--------------------------------------------------"
echo "--------------------------------------------------"
echo -e "--------------------------------------------------\n"

echo "Below you will find the credentials used to connect to your Nextcloud instance."
echo "The credentials are also stored in a file: $HOME/nextlcoud.credentials"

echo -e "\n--------------------------------------------------\n"
echo "DATABASE USER: nextcloud"
echo "DATABASE PASSWORD: $MYSQL_NC_PW"
echo -e "\n--------------------------------------------------\n"

echo -e "\n--------------------------------------------------\n"
echo "NEXTCLOUD WEB ENDPOINT: https://$IP/nextcloud"
echo "NEXTCLOUD USER: admin"
echo "NEXTCLOUD USER PASSWORD: $NC_ADMIN_PW"
echo -e "\n--------------------------------------------------"
}

final_echo
final_echo > "$HOME"/nextlcoud.credentials
