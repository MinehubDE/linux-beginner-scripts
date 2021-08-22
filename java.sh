#!/bin/bash
shopt -s extglob

echo "---------------------------------------------------------------------------------"

if [ "$(id -u)" != "0" ]; then
	echo -e "\n---------------------------------------------------------------------------------\n"
	echo -e "PLEASE EXECUTE THIS SCRIPT AS ROOT OR SUDO!\n"
	echo "sudo ${0}"
	echo -e "\n---------------------------------------------------------------------------------"
	exit 1
fi

echo "NOTICE: Existing Java installations will be overriden !!!"
echo "\"default\" will install the system\'s default Java version."
read -r -p "Which Java version your want to install? [ 8 / 11 / ... / default ] : " VERSION

case $VERSION in
	default)
		apt-get update && apt-get install -y default-jre-headless
		JAVA_ALTERNATIVE=$(update-java-alternatives -l | grep "java-.*-openjdk" | awk '{ print $1 }')
		update-java-alternatives -s "$JAVA_ALTERNATIVE"
	;;
	*([0-9]))
		apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg2 lsb-release wget
		wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
		echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/adoptopenjdk.list
		apt-get update && apt-cache search adoptopenjdk-$VERSION-hotspot | grep "$VERSION"
		if [ $? -ne 0 ]; then
			echo "---------------------------------------------------------------------------------"
			echo "Java $VERSION is unavailable on Adoptopenjdk for your system."
			echo "The following versions are available for your system ($(lsb_release -sc))"
			echo "--------------------------------"
			echo $(apt-cache search adoptopenjdk | sed 's/^adoptopenjdk-//g' | sed 's/-.*//g' | uniq) | sed 's/ / \/ /g'
			echo "--------------------------------"
			echo "Please restart the script and use one of the listed versions."
			exit 1
		fi
		apt-get install -y "adoptopenjdk-$VERSION-hotspot"
		update-java-alternatives -s "adoptopenjdk-$VERSION-hotspot-amd64"
	;;
	*)
		echo "Error in validating input: $VERSION"
		echo "Please enter \"default\" or any number to install the specific Java version."
		echo "The script will exit now."
		exit 1
	;;
esac

echo -e "\n---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo -e "---------------------------------------------------------------------------------\n"
echo "INSTALLTION COMPLETED SUCCESSFULLY"

java -version

echo -e "\n---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo -e "---------------------------------------------------------------------------------\n"

