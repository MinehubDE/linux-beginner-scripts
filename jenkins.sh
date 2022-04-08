#!/bin/bash

printf "\033c"

if [ "$(id -u)" != "0" ]; then
	echo -e "\n---------------------------------------------------------------------------------\n"
	echo -e "PLEASE EXECUTE THIS SCRIPT AS ROOT OR SUDO!\n"
	echo "sudo ${0}"
	echo -e "\n---------------------------------------------------------------------------------"
	exit 1
fi

echo "This script installs Jenkins with all of its dependencies."
read -r -p "Please insert YES to start the installation: " ANSWER

if [ "$ANSWER" != "YES" ]; then
	echo "YES was not entered. Will exit now"
	exit 1
fi

apt-get -y install apt-transport-https

wget -q https://pkg.jenkins.io/debian/jenkins.io.key
apt-key add jenkins.io.key && rm jenkins.io.key

echo "deb https://pkg.jenkins.io/debian binary/" > /etc/apt/sources.list.d/jenkins.list

apt-get update
if [ $? -ne 0 ]; then
	echo "Some of your sources seem to have an error. Please fix them first."
	exit 1
fi
apt-get -y install default-jre-headless
apt-get -y install jenkins host

IP=$(host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has address" | awk '{ print $NF }')

echo -e "\n---------------------------------------------------------------------------------\n"
echo "DONE. You can now navigate to your Jenkins in your browser:"
echo -e "\n---------------------------------------------------------------------------------\n"
echo "http://$IP:8080"
echo -e "\n---------------------------------------------------------------------------------\n"
