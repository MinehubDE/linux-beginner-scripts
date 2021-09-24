# linux-beginner-scripts

This repo containes several scripts to easily setup some basic services on your virtual server / VPS / dedicated server.

## Download the scripts / get the repo

**MAKE SURE YOU ARE LOGGED IN AS ROOT USER, OTHERWISE USE SUDO !**

Without git, use the following to download this repository 

    apt-get install wget unzip
    wget https://github.com/MinehubDE/linux-beginner-scripts/archive/master.zip && unzip master.zip && rm master.zip

If you have git installed, use 

    git clone https://github.com/MinehubDE/linux-beginner-scripts.git


Go into the folder and execute the script of your choice, e.g.

    cd linux-beginner-scripts* && ./bedrock_server.sh

    cd linux-beginner-scripts* && ./jenkins.sh

    cd linux-beginner-scripts* && ./minecraft_server.sh

    cd linux-beginner-scripts* && ./mysql_server.sh

    cd linux-beginner-scripts* && ./nextcloud.sh

    cd linux-beginner-scripts* && ./teamspeak.sh
    
    cd linux-beginner-scripts* && ./java.sh
