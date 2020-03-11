#!/bin/bash

printf "\033c"

if [ "$(id -u)" != "0" ]; then
        echo -e "\n---------------------------------------------------------------------------------\n"
        echo -e "PLEASE EXECUTE THIS SCRIPT AS ROOT OR SUDO!\n"
        echo "sudo ${0}"
        echo -e "\n---------------------------------------------------------------------------------"
        exit 1
fi

DEPENDENCIES="host tar bzip2 wget"
dpkg -s $DEPENDENCIES &>/dev/null
if [ $? -ne 0 ]; then
        echo -e "For this script and TeamSpeak to work we need to install the following dependencies:\n"
        for DEPENDENCY in $DEPENDENCIES; do
                echo "- $DEPENDENCY"
        done
        echo ""
        read -r -p "Please insert 'YES' to allow the installation. Otherwise this script will exit here: " ANSWER
        if [ "$ANSWER" == "YES" ]; then
                apt-get update
                apt-get -y install $DEPENDENCIES
                if [ $? -ne 0 ]; then
                        echo -e "\n---------------------------------------------------------------------------------\n"
                        echo "Installation failed, trying to fix..."
                        echo -e "\n---------------------------------------------------------------------------------\n"
                        sleep 3
                        apt-get -f -y install
                        if [ $? -ne 0 ]; then
                                echo "Could not install dependencies. Will exit now."
                                exit 1
                        fi
                fi
        else
                echo "Your answer was \"$ANSWER\" and not YES. So this script will exit now."
                exit 1
        fi
fi

USERNAME=""
while [ -z "$USERNAME" ] || [ "$USERNAME" == "root" ]; do
        echo -e "---------------------------------------------------------------------------------\n"
        echo "Please insert your desired username that is used to manage the TeamSpeak Server."
        echo "The server will get created in the home directory of the user entered."
        echo -e "Usually the user is named 'teamspeak'\n"
        read -r -p "The user gets created if it does not already exist: " USERNAME
done


id -g "$USERNAME" &>/dev/null
if [ $? -ne 0 ]; then
        groupadd "$USERNAME"
fi

id -u "$USERNAME" &>/dev/null
if [ $? -ne 0 ]; then
        echo -e "\n---------------------------------------------------------------------------------\n"
        echo "User does not exist! To create this user, we need a password!"
        echo -e "\n---------------------------------------------------------------------------------\n"
        PASSWORD=""
        while [ -z "$PASSWORD" ]; do
                read -r -s -p "Please insert the desired password for User $USERNAME: " PASSWORD
        done
        useradd -g "$USERNAME" -d /home/"$USERNAME" -m -s /bin/bash -p $(echo "$PASSWORD" | openssl passwd -1 -stdin) "$USERNAME"
fi

echo -e "\n---------------------------------------------------------------------------------\n"
echo "TeamSpeak is getting installed... Please wait..."
echo -e "\n---------------------------------------------------------------------------------\n"

URL=$(curl -s https://www.teamspeak.com/de/downloads/#server | grep "Download" | grep "server_linux_amd64" | sed 's/.*href="//' | sed 's/">.*//')

wget -q "$URL" -O teamspeak.tar.bz2
tar xjf teamspeak.tar.bz2 -C /home/"$USERNAME" && rm teamspeak.tar.bz2

touch "/home/$USERNAME/teamspeak3-server_linux_amd64/.ts3server_license_accepted"

chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

echo -e "\n---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo -e "---------------------------------------------------------------------------------\n"
echo "SETUP COMPLETED SUCCESSFULLY"

echo -e "\n---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo -e "---------------------------------------------------------------------------------\n"

PASSWORD_OUTPUT=${PASSWORD:=Password for the user was not created with this script, so it existed before.}

echo "Please connect via SSH (e.g. with Putty or another SSH client) using the following credentials:"
echo -e "\n---------------------------------------------------------------------------------\n"

echo "- Username: $USERNAME"
echo "- Password: $PASSWORD_OUTPUT"

echo -e "\n---------------------------------------------------------------------------------\n"

echo "Then execute this command and the server will start:"
echo -e "\n---------------------------------------------------------------------------------\n"

echo "cd /home/$USERNAME/teamspeak3-server_linux_amd64 && ./ts3server_startscript.sh start"

echo -e "\n---------------------------------------------------------------------------------\n"

IP=$(host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has address" | awk '{ print $NF }')

echo "Enter this IP as address into your TeamSpeak client:"
echo -e "\n---------------------------------------------------------------------------------\n"

echo "$IP"

echo -e "\n---------------------------------------------------------------------------------\n"
