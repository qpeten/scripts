#!/bin/bash

# This was never finished (I have used docker instead)

# Created by Quentin Peten on 21/06/2016
#
# Makes all the necessary operations to be able to run multiple instances of transmission-daemon on the same machine.
# This script is supossed to be run after each update of transmission-daemon.
#
# The script leaves the original transmission instance untouched. So, if you put two values in $instances, you'll end up with 3 different instances of transmission; the original, and the two youve just created
# The rpc port is equal the the port of the original transmission daemon +1 for the first instance, +2 for the second, etc.
# Requires jq

## DOES NOT WORK YET

#Settings
	instances=('bruno' 'aymeric')
	downloadDir[0]='/mnt/btrfs/tank/documents/parents/transmission-download'
	downloadDir[1]='/mnt/btrfs/tank/documents/aymeric/transmission-download'
	password=('' '') #Leave empty to disable authentification

#Actual script
j=0
for i in ${instances[@]}
do
	sudo rm -f /usr/bin/transmission-daemon-"$i"
	sudo cp -a /usr/bin/transmission-daemon{,-"i"}
	sudo rm -f /etc/init.d/transmission-daemon-"$i"
	sudo cp -a /etc/init.d/transmission-daemon{,-"$i"}
	sudo rm -rf /etc/transmission-daemon-"$i"
	sudo cp -a  /etc/transmission-daemon{,-"$i"}
	sudo rm -f /etc/default/transmission-daemon-"$i"
	sudo cp -a /etc/default/transmission-daemon{,-"$i"}
	sudo rm -rf /var/lib/transmission-daemon-"$i"
	sudo cp -a  /var/lib/transmission-daemon{,-"$i"}

	sudo sed -i '/^NAME=/s|$|-'"$i"'|' /etc/init.d/transmission-daemon-"$i"

	sudo jq '."download-dir" = "'${downloadDir["$j"]}'"' /etc/transmission-daemon-"$i"/settings.json | \
	sudo jq '."incomplete-dir" = "'${downloadDir["$j"]}/.incomplete'"' | sudo tee /etc/transmission-daemon-"$i"/tmp > /dev/null
        sudo mv /etc/transmission-daemon-"$i"/{tmp,settings.json}

	sudo jq '."peer-port" += '"$((j+1))"'' /etc/transmission-daemon-"$i"/settings.json | \
        sudo jq '."rpc-port" += '"$((j+1))"'' | sudo tee /etc/transmission-daemon-"$i"/tmp > /dev/null
        sudo mv /etc/transmission-daemon-"$i"/{tmp,settings.json}

	if [ -z ${password["$j"]} ]; then
		sudo jq '."rpc-authentication-required" = "false"' /etc/transmission-daemon-"$i"/settings.json | sudo tee /etc/transmission-daemon-"$i"/tmp > /dev/null
	else
		sudo jq '."rpc-authentication-required" = "true"' /etc/transmission-daemon-"$i"/settings.json | \
		sudo jq '."rpc-password" = "'${password["$j"]}'"' | sudo tee /etc/transmission-daemon-"$i"/tmp > /dev/null
	fi
	sudo mv /etc/transmission-daemon-"$i"/{tmp,settings.json}

	sudo sed -i '/^CONFIG_DIR=/s|\/info|-'"$i"'\/info|' /etc/default/transmission-daemon-"$i"

	j=$j+1
done
