#!/bin/bash

# Set the defaults. These can be overridden by specifying the value as an
# environment variable when running this script.
INCLUDE_OPENSSH="${INCLUDE_OPENSSH:-true}"
INCLUDE_SAKURA="${INCLUDE_SAKURA:-true}"
INCLUDE_PROTONFIX="${INCLUDE_PROTONFIX:-true}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
STEAM_USER="${STEAM_USER:-steam}"
export STEAM_USER

# Configure the default versions of the SteamOS packages to use. These generally
# don't ever need to be overridden.
STEAMOS_COMPOSITOR_VER="${STEAMOS_COMPOSITOR_VER:-1.35+bsos1_amd64}"
STEAMOS_MODESWITCH_VER="${STEAMOS_MODESWITCH_VER:-1.10+bsos1_amd64}"
STEAMOS_PLYMOUTH_VER="${STEAMOS_PLYMOUTH_VER:-0.17+bsos2_all}"

# Ensure the script is being run as root
if [ "$EUID" -ne 0 ]; then
	echo "This script must be run with sudo."
	exit
fi

# Confirm from the user that it's OK to continue
if [[ "${NON_INTERACTIVE}" != "true" ]]; then
	echo "This script will configure a SteamOS-like experience on Ubuntu."
	read -p "Do you want to continue? [Yy] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Starting installation..."
	else
		echo "Aborting installation."
		exit
	fi
fi

# Adding a question about setting the default user just in case it wasn't 
# set as an environment variable.
if [[ "${NON_INTERACTIVE}" != "true" ]]; then
	read -p "Do you want to change the default user? [Yy] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		read -p "What name should the default user be? " -r
		echo
		if [[ "$REPLY" != "" ]]; then
			STEAM_USER="$REPLY"
			echo "Default user is setting to '$STEAM_USER'"
			read -p "Is that correct? [Yy] " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				echo "Starting installation..."
				export STEAM_USER
			else
				echo "Aborting installation."
				exit
			fi
		fi
	else
		echo "Continuing installation."
	fi
fi

# See if there is a 'steam' user account. If not, create it.
if ! grep "^${STEAM_USER}" /etc/passwd > /dev/null; then
	echo "Steam user '${STEAM_USER}' not found. Creating it..."
	adduser --disabled-password --gecos "" "${STEAM_USER}"
fi
STEAM_UID=$(grep "^${STEAM_USER}" /etc/passwd | cut -d':' -f3)
STEAM_GID=$(grep "^${STEAM_USER}" /etc/passwd | cut -d':' -f4)
echo "Steam user '${STEAM_USER}' found with UID ${STEAM_UID} and GID ${STEAM_GID}"

# Choosing from the guide in Proton (SteamPlay) Wiki https://github.com/ValveSoftware/Proton/wiki/Requirements
# Check Graphic card
echo "What is your Graphic Card Manufacturer"
echo "1) Nvidia"
echo "2) AMD"
echo "3) Intel"
read case;

case $case in
	1)	echo "Getting Latest Graphic Drivers..."
		add-apt-repository ppa:graphics-drivers/ppa
		apt update
		apt install nvidia-driver-415 -y;;
	2)	echo "Getting Latest AMD Graphic Drivers..."
		add-apt-repository ppa:oibaf/graphics-drivers
		apt update
		apt apt -y upgrade;;
	3)	echo "Getting Latest Intel Graphic Drivers..."
		add-apt-repository ppa:paulo-miguel-dias/pkppa
		apt update
		apt dist-upgrade
		apt install mesa-vulkan-drivers mesa-vulkan-drivers:i386 -y;;
esac 

# Install steam and steam device support.
echo "Installing steam..."
apt update
apt install steam steam-devices -y

# WIP - find a way to enable Steamplay without using Desktop Steam Client. Also maybe find a way to enable Steam Beta with latest Steamplay
# Enable SteamPlay
#echo "Enable Steamplay..."

# Enable Protonfix for ease of use with certain games that needs tweaking.
# https://github.com/simons-public/protonfixes
# Installing Protonfix for ease of use
if [[ "${INCLUDE_PROTONFIX}" == "true" ]]; then
	apt install python-pip python3-pip -y
	echo "Installing protonfix..."    
	pip3 install protonfixes --upgrade
	# Installing cefpython3 for visual progress bar
	pip install cefpython3
	# Edit Proton * user_settings.py
fi

# Install a terminal emulator that can be added from Big Picture Mode.
if [[ "${INCLUDE_SAKURA}" == "true" ]]; then
	echo "Installing the sakura terminal emulator..."
	apt install sakura -y
fi

# Install openssh-server for remote administration
if [[ "${INCLUDE_OPENSSH}" == "true" ]]; then
	echo "Installing OpenSSH Server..."
	apt install openssh-server -y
fi

# Download the packages we need. If we fail at downloading, stop the script.
set -e
echo "Downloading SteamOS packages..."
wget "http://repo.steamstatic.com/steamos/pool/main/s/steamos-compositor/steamos-compositor_${STEAMOS_COMPOSITOR_VER}.deb"
wget "http://repo.steamstatic.com/steamos/pool/main/s/steamos-modeswitch-inhibitor/steamos-modeswitch-inhibitor_${STEAMOS_MODESWITCH_VER}.deb"
wget "http://repo.steamstatic.com/steamos/pool/main/p/plymouth-themes-steamos/plymouth-themes-steamos_${STEAMOS_PLYMOUTH_VER}.deb"
set +e

# Enable automatic login. We use 'envsubst' to replace the user with ${STEAM_USER}.
echo "Enabling automatic login..."
envsubst < ./conf/custom.conf > /etc/gdm3/custom.conf

# Create our session switching scripts to allow rebooting to the desktop
echo "Creating reboot to session scripts..."
envsubst < ./conf/reboot-to-desktop-mode.sh > /usr/local/sbin/reboot-to-desktop-mode
envsubst < ./conf/reboot-to-steamos-mode.sh > /usr/local/sbin/reboot-to-steamos-mode
chmod +x /usr/local/sbin/reboot-to-desktop-mode
chmod +x /usr/local/sbin/reboot-to-steamos-mode
echo "Adding scripts to sudoers directory in case you want a password."
echo "You will still need your user as admin to use sudo"
cp ./conf/steamos-reboot.sh /etc/sudoers.d/steamos-reboot
chmod 440 /etc/sudoers.d/steamos-reboot

# Install the steamos compositor, modeswitch, and themes
echo "Configuring the SteamOS boot themes..."
dpkg -i ./*.deb &>/dev/null
apt install -f -y
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/steamos/steamos.plymouth 100
update-alternatives --set default.plymouth /usr/share/plymouth/themes/steamos/steamos.plymouth

# Update the grub theme.
echo 'GRUB_BACKGROUND=/usr/share/plymouth/themes/steamos/steamos_branded.png' | tee -a /etc/default/grub
update-grub

# Set the X session to use the installed steamos session
echo "Configuring the default session..."
cp ./conf/steam-session.conf "/var/lib/AccountsService/users/${STEAM_USER}"

echo ""
echo "Installation complete! Press ENTER to reboot or CTRL+C to exit"
read -r
reboot
