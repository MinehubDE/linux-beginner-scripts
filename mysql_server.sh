#!/bin/bash

printf "\033c"

if [ "$(id -u)" != "0" ]; then
        echo -e "\n---------------------------------------------------------------------------------\n"
        echo -e "PLEASE EXECUTE THIS SCRIPT AS ROOT OR SUDO!\n"
        echo "sudo ${0}"
        echo -e "\n---------------------------------------------------------------------------------"
        exit 1
fi

echo "This script installs MySQL with all of its dependencies."
read -r -p "Please insert YES to start the installation: " ANSWER

if [ "$ANSWER" != "YES" ]; then
        echo "YES was not entered. Will exit now"
        exit 1
fi

apt-get update
if [ $? -ne 0 ]; then
        echo "Some of your sources seem to have an error. Please fix them first."
        exit 1
fi

apt-get -y install mariadb-server

echo -e "\n---------------------------------------------------------------------------------\n"
MYSQL_PW=""
while [ -z "$MYSQL_PW" ]; do
        read -r -s -p "Please insert the desired password for the root user of your mysql server: " MYSQL_PW
done
echo -e "\n---------------------------------------------------------------------------------\n"

# Make sure that root has a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$MYSQL_PW') WHERE User = 'root'" &>/dev/null
# remove anonymous user
mysql -e "DROP USER ''@'localhost'" &>/dev/null
# remove anonymous user for hostname
mysql -e "DROP USER ''@'$(hostname)'" &>/dev/null
# remove test database
mysql -e "DROP DATABASE test" &>/dev/null
# flush everything
mysql -e "FLUSH PRIVILEGES" &>/dev/null
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param

read -r -p "Do you want the database to be publicly accessible? [YES/NO]" PUBLIC

if [[ "$PUBLIC" =~ ^(YES|yes|y)$ ]]; then
        echo "YES was not entered. Database will stay only locally accessible."
else
	sed -i 's/^bind-address.*/#bind-address = 127.0.0.1/' /etc/mysql/mariadb.conf.d/50-server.cnf
	systemctl restart mariadb
fi

echo -e "\n---------------------------------------------------------------------------------\n"
echo "DONE. You can now type 'mysql' as root without any password and start using your database server!"
echo -e "\n---------------------------------------------------------------------------------\n"
