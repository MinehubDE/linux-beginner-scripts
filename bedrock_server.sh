#!/bin/bash

printf "\033c"

if [ "$(id -u)" != "0" ]; then
	echo -e "\n---------------------------------------------------------------------------------\n"
	echo -e "PLEASE EXECUTE THIS SCRIPT AS ROOT OR SUDO!\n"
	echo "sudo ${0}"
	echo -e "\n---------------------------------------------------------------------------------"
	exit 1
fi

USERNAME=""
while [ -z "$USERNAME" ] || [ "$USERNAME" == "root" ]; do
	echo -e "---------------------------------------------------------------------------------\n"
	echo "Please insert your desired username that is used to manage the Minecraft server."
	echo -e "The server will get created in the home directory of the user entered.\n"
	read -r -p "The user gets created if it does not already exist: " USERNAME
done


id -g $USERNAME &>/dev/null
if [ $? -ne 0 ]; then
        groupadd "$USERNAME"
fi

id -u $USERNAME &>/dev/null
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

echo -e "What Software should the server run on?\n"
echo "[1] POCKETMINE (PHP)"
echo "[2] ALTAY (PHP)"
echo "[3] NUKKIT (Java)"
echo "[4] BEDROCK (Official Bedrock Edition of Mojang)"

CASE=1
while [ $CASE -ne 0 ]; do
	read -r -p "Please enter the number of your choice: " TYPE_INT
	case $TYPE_INT in
		1)
		TYPE="pocketmine"
		EXTRA_DEPENDENCIES="PHP"
		CASE=0
		;;
		2)
		TYPE="altay"
		EXTRA_DEPENDENCIES="PHP"
		CASE=0
		;;
		3)
		TYPE="nukkit"
		EXTRA_DEPENDENCIES="JAVA"
		CASE=0
		;;
		4)
		TYPE="bedrock"
		EXTRA_DEPENDENCIES="BULLSHIT"
		CASE=0
		;;
	esac
done

DEPENDENCIES="ca-certificates screen wget host"
dpkg -s $DEPENDENCIES &>/dev/null
if [ $? -ne 0 ]; then
        echo -e "For Minecraft to work we need to install the following dependencies:\n"
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
		case $EXTRA_DEPENDENCIES in
			PHP)
			wget -q https://jenkins.pmmp.io/job/PHP-7.2-Linux-x86_64/lastSuccessfulBuild/artifact/PHP_Linux-x86_64.tar.gz -O /tmp/PHP.tar.gz
			tar xzf /tmp/PHP.tar.gz -C /usr/local/lib/
			ln -s /usr/local/lib/bin/php7/bin/php /usr/local/bin/php
			;;
			JAVA)
			apt-get -y install openjdk-8-jre-headless
			;;
			BULLSHIT)
			;;
		esac
        else
                echo "Your answer was \"$ANSWER\" and not YES. So this script will exit now."
                exit 1
        fi
fi

echo -e "\n---------------------------------------------------------------------------------\n"
echo "Your server is getting created... Please wait..."
echo -e "\n---------------------------------------------------------------------------------\n"

case $TYPE in
	pocketmine)
		rm -f /home/"$USERNAME"/*.phar
		wget -q https://jenkins.pmmp.io/job/PocketMine-MP/lastSuccessfulBuild/artifact/PocketMine-MP.phar -O /home/"$USERNAME"/"$TYPE".phar
		cat > /home/"$USERNAME"/start.sh << EOF
#!/bin/bash

screen -S mcpocket php $TYPE.phar

EOF
	;;
	altay)
		rm -f /home/"$USERNAME"/*.phar
		apt-get install -y unzip
		wget -q https://altay.minehub.de/job/Altay/lastSuccessfulBuild/artifact/plugins/Altay/*zip*/Altay.zip -O /tmp/altay.zip
		unzip /tmp/altay.zip -d /tmp/altay
		mv /tmp/altay/Altay/Altay*.phar /home/"$USERNAME"/"$TYPE".phar
		cat > /home/"$USERNAME"/start.sh << EOF
#!/bin/bash

screen -S mcpocket php $TYPE.phar

EOF
	;;
	nukkit)
		rm -f /home/"$USERNAME"/*.jar
		wget -q https://ci.nukkitx.com/job/NukkitX/job/Nukkit/job/master/lastSuccessfulBuild/artifact/target/nukkit-1.0-SNAPSHOT.jar -O /home/"$USERNAME"/"$TYPE".jar
		cat > /home/"$USERNAME"/start.sh << EOF
#!/bin/bash

screen -S minecraft java -jar $TYPE.jar nogui

EOF
	;;
	bedrock)
		rm -f /home/"$USERNAME"/bedrock_server
	;;
esac

echo "eula=true" > /home/"$USERNAME"/eula.txt
echo "server-port=19132" > /home/"$USERNAME"/server.properties
chmod +x /home/"$USERNAME"/start.sh
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

echo "cd /home/"$USERNAME" && ./start.sh"

echo -e "\n---------------------------------------------------------------------------------\n"

IP=$(host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has address" | awk '{ print $NF }')

echo "Enter this address into your minecraft client and connect to the server:"
echo -e "\n---------------------------------------------------------------------------------\n"

echo "$IP:19132"

echo -e "\n---------------------------------------------------------------------------------\n"
