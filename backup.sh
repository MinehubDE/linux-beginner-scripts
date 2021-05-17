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

read -r SRCDIR
echo ""

while :; do
if [ -d "$SRCDIR" ]; then
	break
else 
	if [ "$SRCDIR" == "l" ] || [ "$SRCDIR" == "exit" ] || [ "$SRCDIR" == "q" ] || [ "$SRCDIR" == "leave" ] || [ "$SRCDIR" == "quit" ]; then
		echo "You have cancelled the script. So this script will exit now."
		exit 1
	else
		echo "Error: Not a valid path"
		echo -e "Please enter the source backup folder, which get archived for example '/home/backup'\n"
		read -r SRCDIR
		echo ""
	fi
fi
done

#----------------------------------------------------------
# Destionation Backup Folder
#----------------------------------------------------------

echo -e "Please enter the destination backup folder, which get archived for example '/home/backup'\n"

read -r DESDIR
echo ""

while :; do
if ! [ "$DESDIR" = "$SRCDIR" ]; then
	if [ -d "$DESDIR" ]; then
		break
	else 
		echo "Error: Not a valid path"
		echo -e "Please enter the destination backup folder, which get archived for example '/home/backup'\n"
		read -r DESDIR
		echo ""
	fi
elif [ "$DESDIR" == "l" ] || [ "$DESDIR" == "exit" ] || [ "$DESDIR" == "q" ] || [ "$DESDIR" == "leave" ] || [ "$DESDIR" == "quit" ]; then
		echo "You have cancelled the script. So this script will exit now."
		exit 1
else
	echo -e "Error: You have the same path"
	echo -e "Please enter the destination backup folder, which get archived for example '/home/backup'\n"
	read -r DESDIR
	echo ""
fi
done

#----------------------------------------------------------
# Filename
#----------------------------------------------------------

read -r -p "Please enter the desired name of the backup that comes before the time: " FPART

echo ""

VALIDATE='[^a-zA-Z]'

while :; do
if [[ $FPART =~ $VALIDATE ]]; then
	if [ "$FPART" == "l" ] || [ "$FPART" == "exit" ] || [ "$FPART" == "q" ] || [ "$FPART" == "leave" ] || [ "$FPART" == "quit" ]; then
			echo "You have cancelled the script. The script will exit now."
			exit 1
	else
		echo "Error: Not a valid filename"
		read -r -p "Please enter the name of the backup that comes before the time: " FPART
		echo ""
	fi
else
	break
fi
done

#----------------------------------------------------------
# Backup time
#----------------------------------------------------------

echo -e "Do you want that the script will be executed automatically?\n"

read -r -p "Please insert 'YES' if you want it, otherwise it would be skipped! " ANSWER

echo ""

if [ "$ANSWER" == "YES" ] || [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "yes" ]; then

echo -e "Enter time in hour (0 - 23) when the backup should be daily generated\n"

read -r CRONTAB

re='^[0-9]+$'

while :; do
if ! [[ $CRONTAB =~ $re ]] ; then
		if [ "$CRONTAB" == "l" ] || [ "$CRONTAB" == "exit" ] || [ "$CRONTAB" == "q" ] || [ "$CRONTAB" == "leave" ] || [ "$CRONTAB" == "quit" ]; then
			echo "You have cancelled the script. So this script will exit now."
			exit 1
		else
			echo "Error: Not a number"
			echo -e "Enter time in hour (0 - 23) when the backup should be daily generated\n"
			read -r CRONTAB
			echo ""
		fi
else
	( crontab -l | grep -v -F 'tar' ; echo "00 0$CRONTAB * * * /bin/bash tar -cpzf $DESDIR/$FPART-date +%d-%m-%y-%H-%M.tar.gz -P $SRCDIR" ) | crontab -
	echo -e "Setup done!"
	echo -e "The backup process was completed successfully."
	break
fi
done

else
	echo "Your answer was \"$ANSWER\" and not YES. Therefore this step will be skipped...."
	echo -e "Setup done!"
	echo -e "The backup process was completed successfully."
fi


