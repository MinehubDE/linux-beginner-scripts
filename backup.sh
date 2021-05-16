#!/bin/bash

printf "\033c"

if [ "$(id -u)" != "0" ]; then
	echo -e "\n---------------------------------------------------------------------------------\n"
	echo -e "PLEASE EXECUTE THIS SCRIPT AS ROOT OR SUDO!\n"
	echo -e "YOU CAN ALWAYS CANCEL THE SCRIPT WITH 'leave'!\n"
	echo "sudo ${0}"
	echo -e "\n---------------------------------------------------------------------------------"
	exit 1
fi

#----------------------------------------------------------
# Source Backup Folder
#----------------------------------------------------------

echo -e "Enter source backup folder\n"

read SRCDIR

while :; do
if ! [ $SRCDIR -ne 0 ]; then
	if [ -d "$SRCDIR" ]; then
		break
	else 
		if [ "$SRCDIR" == "l" ] || [ "$SRCDIR" == "exit" ] || [ "$SRCDIR" == "q" || [ "$SRCDIR" == "leave"]; then
			echo "This script will exit now."
			exit 1
		else
			echo "Error: Not a valid path"
			echo -e "Enter source backup folder\n"
			read SRCDIR
		fi
	fi
else
	break
fi
done

#----------------------------------------------------------
# Destionation Backup Folder
#----------------------------------------------------------

echo -e "Enter destination backup folder\n"

read DESDIR

while :; do
if [ $DESDIR = $SRCDIR ]; then
	if ! [ $DESDIR -ne 0 ]; then
		if [ -d "$DESDIR" ]; then
			break
		else 
			if [ "$DESDIR" == "l" ] || [ "$DESDIR" == "exit" ] || [ "$DESDIR" == "q" || [ "$DESDIR" == "leave"]; then
				echo "This script will exit now."
				exit 1
			else
				echo "Error: Not a valid path"
				echo -e "Enter source backup folder\n"
				read DESDIR
			fi
		fi
	else
		break
	fi
else
	echo "Error: You have the same path"
	echo -e "Enter source backup folder\n"
	read DESDIR
fi
done

#----------------------------------------------------------
# Backup time
#----------------------------------------------------------

echo -e "Do you want that the script will be executed automatically?\n"

read -r -p "Please insert 'YES' if you want it, otherwise it would be skipped! " ANSWER

if [ "$ANSWER" == "YES" ] || [ "$ANSWER" == "y" ]; then

echo -e "Enter time in hour (0 - 23) when the backup should be daily generated\n"

read CRONTAB

re='^[0-9]+$'

while :; do
if ! [[ $CRONTAB =~ $re ]] ; then
		if [ "$CRONTAB" == "l" ] || [ "$CRONTAB" == "exit" ] || [ "$CRONTAB" == "q" ] || [ "$CRONTAB" == "leave" ]; then
			echo "This script will exit now."
			exit 1
		else
			echo "Error: Not a number"
			echo -e "Enter time"
			read CRONTAB
		fi
else
	break
fi
done

crontab -e
echo "00 $CRONTAB * * * /bin/bash /root/backup.sh >/dev/null 2>&1"

echo -e "The script must be in the root dictionary otherwise it wont work\n"

else
	echo "Your answer was \"$ANSWER\" and not YES. So this step gets skipped..."
fi

#----------------------------------------------------------
# Filename
#----------------------------------------------------------

echo -e "Enter your first part of the filename in front of the time\n"

read $FPART

VALIDATE='^[0-9a-zA-Z._-]+$'

while :; do
if ! [ $FPART =~ $VALIDATE ]; then
	if [ "$FPART" == "l" ] || [ "$FPART" == "exit" ] || [ "$FPART" == "q" ]; then
			echo "This script will exit now."
			exit 1
		else
			echo "Error: Not a valid filename"
			echo -e "Enter your first part of the filename\n"
			read FPART
		fi
else
	break
fi
done

TIME=`date +%d-%m-%y-%H-%M`  

FILENAME=$FPART-$TIME.tar.gz 

#----------------------------------------------------------
# Generate new file
#----------------------------------------------------------

echo "FFILENAME=$FILENAME" > backup-temp.sh
echo "DDESDIR=$DESDIR" > backup-temp.sh
echo "SSRCDIR=$SSRCDIR" > backup-temp.sh
echo "$content" > backup-temp.sh

content="
tar -cpzf $DDESDIR/$FFILENAME -P $SSRCDIR

echo -e "You want to change the paths?\n"

read -r -p "Please insert 'YES' if you want it, otherwise it would be skipped! " NEW

re='^[0-9]+$'

if [ "$ANSWER" == "YES" ] || [ "$ANSWER" == "y" ]; then
	echo "Loading..."
	
	cd /root
	wget https://github.com/crafter23456/linux-beginner-scripts/blob/master/backup.sh
	cd /root && ./backup.sh
	
	rm -- "$0"
	else
		echo "Your answer was \"$ANSWER\" and not YES. So this script will exit now."
		exit 1
fi
"

# removes the script & rename the temp to main
rm -- "$0"
cd ${BASH_SOURCE[0]}
mv backup-temp.sh backup.sh