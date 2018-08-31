#!/bin/bash

# Set the defaults. These can be overridden by specifying the value as an
# environment variable when running this script.
INCLUDE_OPENSSH="${INCLUDE_OPENSSH:-true}"
INCLUDE_SAKURA="${INCLUDE_SAKURA:-true}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
STEAM_USER="${STEAM_USER:-steam}"
export STEAM_USER

# Configure the default versions of the SteamOS packages to use. These generally
# don't ever need to be overridden.
STEAMOS_COMPOSITOR_VER="${STEAMOS_COMPOSITOR_VER:-1.34+bsos1_amd64}"
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
	read -p "Do you want to continue? [Yy]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Starting installation..."
	else
		echo "Aborting installation."
		exit
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

# Install steam and steam device support.
echo "Installing steam..."
apt update
apt install steam steam-devices -y

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
