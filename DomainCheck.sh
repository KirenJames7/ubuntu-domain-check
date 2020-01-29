#!/bin/bash
#----AUTHOR:----------Kiren James
#----CONTRIBUTORS:----Kiren James
#
# ===================================================================
# CONFIG - Only edit the below lines to setup the script
# ===================================================================
#
# Company & Domain settings
DOMAIN_NAME="<Company-Domain-Name>"
USER_COUNT=<Number-Of-User-Accounts>
WIFI_NAME="<Company-WiFi-Name>"
#
# ===================================================================
# DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING
# ===================================================================
#
# FUNCTIONS START HERE
function displayHostName {
	# Write the currenly set hostname
	hostname=`hostname`
	echo "Current computer name: ${hostname}"
}

function domainCheck {
	# Check if the client is connected to the domain
	currentdomain=`dnsdomainname`
	if [ ${currentdomain} == ${DOMAIN_NAME} ]; then
		echo "Connected to domain: ${currentdomain}"
	else
		echo "Not connected to domain"
		exit 0
	fi
}

function listCurrentUsers {
	# Get users as array
	users=(`cut -d' ' -f1 /etc/sudoers.d/sudo-users`)
	
	if [ ${#users[@]} -ne ${USER_COUNT} ]; then
		# Inform to check the users if user count is less than usual
		echo "Check added users:"
		for user in ${users[@]}
		do
			echo ${user}
		done
	else
		# List the users
		echo "List current users:"
		for user in ${users[@]}
		do
			echo ${user}
		done
	fi
}

function wifiCheck {
	# Get connected wifi SSID
	connectedwifi=`iwgetid -r`
	if [ ${connectedwifi} == ${WIFI_NAME} ]; then
		echo "WiFi setup complete."
	elif [ `nmcli c | grep -o ${WIFI_NAME}` == ${WIFI_NAME} ]; then # Check if WiFi is saved
		# Try to connect to WiFi 
		#nmtui connect ${WIFI_NAME} >/dev/null 2>&1
		echo "Try connecting to WiFi & run command 'wificheck' to test again."
	else
		echo "Please re-check WiFi."
	fi
}

function addDomainCheckToBashRC {
	# Add function to use in terminal in future
	# Check if command already exists
	bashrc=`cat ~/.bashrc | grep -o domaincheck`
	if [ -z ${bashrc} ]; then
		# Promt user for sudo password
		# read -s -p "Enter sudo password: " password
		# Copy script to local directory
		echo ${password} | sudo -S cp ${PWD}/DomainCheck.sh /opt/DomainCheck.sh
		# Make file executable
		sudo chmod +x /opt/DomainCheck.sh
		echo >> ~/.bashrc
		# Add command to cli
		echo "alias domaincheck='/opt/DomainCheck.sh'" >> ~/.bashrc
		# Reset the shell to use this command immediately
		. ~/.bashrc
		
		echo "Successfully installed as command for future use. Run the command domaincheck."
	fi
}

function addWiFiCheckToBashRC {
	# Add function to use in terminal in future
	# Check if command already exists
	bashrc=`cat ~/.bashrc | grep -o wificheck`
	if [ -z ${bashrc} ]; then
		# Create script file
		touch WiFiCheck.sh
		# Write scripts to file
		echo "WIFI_NAME='${WIFI_NAME}'"
		echo "# Get connected wifi SSID" >> WiFiCheck.sh
		echo "connectedwifi=`iwgetid -r`" >> WiFiCheck.sh
		echo "if [ -z ${connectedwifi}  ]; then" >> WiFiCheck.sh
		echo "# Not connected to wifi" >> WiFiCheck.sh
		echo "	echo  'Please re-check WiFi'." >> WiFiCheck.sh
		echo "elif [ -z ${connectedwifi} == ${WIFI_NAME} ]; then" >> WiFiCheck.sh
		echo "# WiFi connected to network" >> WiFiCheck.sh
		echo "	echo 'WiFi setup complete.'" >> WiFiCheck.sh
		echo "elif [ `nmcli c | grep -o ${WIFI_NAME}` == ${WIFI_NAME} ]; then # Check if WiFi is saved" >> WiFiCheck.sh
		echo "# WiFi saved but not connected" >> WiFiCheck.sh
		echo "	echo 'Try connecting to WiFi & run command wificheck to test again.'" >> WiFiCheck.sh
		echo "fi" >> WiFiCheck.sh
		# Promt user for sudo password
		# read -s -p "Enter sudo password: " password
		# Copy script to local directory
		echo ${password} | sudo -S mv ${PWD}/WiFiCheck.sh /opt/WiFiCheck.sh
		echo >> ~/.bashrc
		# Add command to cli
		echo "alias wificheck='/opt/WiFiCheck.sh'" >> ~/.bashrc
		# Make file executable
		sudo chmod +x /opt/WiFiCheck.sh
		# Reset the shell to use this command immediately
		. ~/.bashrc
		
		echo "Successfully installed as command for future use. Run the command wificheck."
		
		bash -c 'exec bash'
		# trap  "kill -9 $main" EXIT < Testing
	fi
}

function continueScript {
	displayHostName
	domainCheck
	listCurrentUsers
	wifiCheck
	addDomainCheckToBashRC
	addWiFiCheckToBashRC
}

function promptSudoerPassword {
	# Prompt for sudoer password
	read -s -p "sudo password: " password
	echo
}

function sudoerPasswordCheck {
	# Check input sudoer password & continue script on success or propmt sudoer password on fail
	echo ${password} | sudo -S true 2>/dev/null && continueScript || (echo Incorrect password, please try again && promptSudoerPassword)
}

function sudoerCheck {
	# Check if terminal has sudo privileges
	if sudo -n true 2>/dev/null; then
		# Continue script
		continueScript
	else
		# Prompt for sudoer password
		promptSudoerPassword
		sudoerPasswordCheck
	fi
}

function currentUserSudoerCheck {
	currentuser=`whoami`
	sudoer=`getent group sudo | grep -o ${currentuser}`
	if [ -z ${sudoer} ]; then
		echo "Current user does not have sudo priviledges. Exiting script."
		exit 0
	else
		sudoerCheck
	fi
}

# Script begins here
hostname=""
currentdomain=""
currentUserSudoerCheck
