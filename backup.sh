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

echo -e "Please enter the source backup folder, which get archived for example '/home/backup'\n"

read SRCDIR

while :; do
if [ -d "$SRCDIR" ]; then
	break
else 
	if [ "$SRCDIR" == "l" ] || [ "$SRCDIR" == "exit" ] || [ "$SRCDIR" == "q" || [ "$SRCDIR" == "leave" || [ "$SRCDIR" == "quit" ]; then
		echo "You have cancelled the script. So this script will exit now."
		exit 1
	else
		echo "Error: Not a valid path"
		echo -e "Please enter the source backup folder, which get archived for example '/home/backup'\n"
		read SRCDIR
	fi
fi
done

#----------------------------------------------------------
# Destionation Backup Folder
#----------------------------------------------------------

echo -e "Please enter the destination backup folder, which get archived for example '/home/backup'\n"

read DESDIR

while :; do
if ! [ $DESDIR = $SRCDIR ]; then
	if [ -d "$DESDIR" ]; then
		break
	else 
		echo "Error: Not a valid path"
		echo -e "Please enter the destination backup folder, which get archived for example '/home/backup'\n"
		read DESDIR
	fi
elif [ "$DESDIR" == "l" ] || [ "$DESDIR" == "exit" ] || [ "$DESDIR" == "q" ] || [ "$DESDIR" == "leave" || [ "$DESDIR" == "quit" ]; then
		echo "You have cancelled the script. So this script will exit now."
		exit 1
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

if [ "$ANSWER" == "YES" ] || [ "$ANSWER" == "y" || [ "\$ANSWER" == "Y" || [ "\$ANSWER" == "yes" ]; then

echo -e "Enter time in hour (0 - 23) when the backup should be daily generated\n"

read CRONTAB

re='^[0-9]+$'

while :; do
if ! [[ $CRONTAB =~ $re ]] ; then
		if [ "$CRONTAB" == "l" ] || [ "$CRONTAB" == "exit" ] || [ "$CRONTAB" == "q" ] || [ "$CRONTAB" == "leave" || [ "$CRONTAB" == "quit" ]; then
			echo "You have cancelled the script. So this script will exit now."
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

crontab -r backupscript
crontab -e backupscript | { cat; echo echo "00 $CRONTAB * * * /bin/bash tar -cpzf $DESDIR/$FILENAME -P $SRCDIR >/dev/null 2>&1"; } | crontab -

else
	echo "Your answer was \"$ANSWER\" and not YES. Therefore this step will be skipped...."
fi

#----------------------------------------------------------
# Filename
#----------------------------------------------------------

read -r -p "Please enter the desired name of the backup that comes before the time: " FPART

VALIDATE='[^a-zA-Z]'

while :; do
if [[ $FPART =~ $VALIDATE ]]; then
	if [ "$FPART" == "l" ] || [ "$FPART" == "exit" ] || [ "$FPART" == "q" || [ "$FPART" == "leave" || [ "$FPART" == "quit" ]; then
			echo "You have cancelled the script. The script will exit now."
			exit 1
	else
		echo "Error: Not a valid filename"
		read -r -p "Please enter the name of the backup that comes before the time: " FPART
	fi
else
	echo -e "Setup done!"
	echo -e "The backup process was completed successfully."
	break
fi
done
