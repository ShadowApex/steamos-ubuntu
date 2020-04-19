#!/bin/bash

# Set the defaults. These can be overridden by specifying the value as an
# environment variable when running this script.
INCLUDE_OPENSSH="${INCLUDE_OPENSSH:-false}"
INCLUDE_SAKURA="${INCLUDE_SAKURA:-false}"
INCLUDE_PROTONFIX="${INCLUDE_PROTONFIX:-false}"
INCLUDE_GPU_DRIVERS="${INCLUDE_GPU_DRIVERS:-false}"
UPDATE_CONFFILES="${UPDATE_CONFFILES:-true}"
GPU_TYPE="${GPU_TYPE:-auto}"
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
	echo "Options:"
	echo "  OpenSSH:      ${INCLUDE_OPENSSH}"
	echo "  Terminal:     ${INCLUDE_SAKURA}"
	echo "  Proton Fixes: ${INCLUDE_PROTONFIX}"
	echo "  GPU Drivers:  ${INCLUDE_GPU_DRIVERS}"
	echo "    GPU Type:   ${GPU_TYPE}"
	echo "  Steam User:   ${STEAM_USER}"
	echo "  Update Config:${UPDATE_CONFFILES}"
	echo ""
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

# See if there is a 'steam' user account. If not, create it.
if ! grep "^${STEAM_USER}" /etc/passwd > /dev/null; then
	echo "Steam user '${STEAM_USER}' not found. Creating it..."
	adduser --disabled-password --gecos "" "${STEAM_USER}"
fi
STEAM_UID=$(grep "^${STEAM_USER}" /etc/passwd | cut -d':' -f3)
STEAM_GID=$(grep "^${STEAM_USER}" /etc/passwd | cut -d':' -f4)
echo "Steam user '${STEAM_USER}' found with UID ${STEAM_UID} and GID ${STEAM_GID}"

# Choosing from the guide in Proton (SteamPlay) Wiki https://github.com/ValveSoftware/Proton/wiki/Requirements
# Install the GPU drivers if it was specified by the user.
if [[ "${INCLUDE_GPU_DRIVERS}" == "true" ]]; then

	# Autodetect the GPU so we can install the appropriate drivers.
	if [[ "${GPU_TYPE}" == "auto" ]]; then
		echo "Auto-detecting GPU..."
		if lspci | grep -i vga | grep -iq nvidia; then
			echo "  Detected Nvidia GPU"
			GPU_TYPE="nvidia"
		elif lspci | grep -i vga | grep -iq amd; then
			echo "  Detected AMD GPU"
			GPU_TYPE="amd"
		elif lspci | grep -i vga | grep -iq intel; then
			GPU_TYPE="intel"
			echo "  Detected Intel GPU"
		else
			GPU_TYPE="none"
			echo "  Unable to determine GPU. Skipping driver install."
		fi
	fi

	# Install the GPU drivers.
	case "${GPU_TYPE}" in
		nvidia)
			echo "Installing the latest Nvidia drivers..."
			add-apt-repository ppa:graphics-drivers/ppa -y
			apt update
			apt install nvidia-driver-415 -y
			;;
		amd)
			echo "Installing the latest AMD drivers..."
			add-apt-repository ppa:oibaf/graphics-drivers -y
			apt update
			apt dist-upgrade -y

			dpkg --add-architecture i386
			apt update
			apt install mesa-vulkan-drivers mesa-vulkan-drivers:i386 -y
			;;
		intel)
			echo "Installing the latest mesa drivers..."
			add-apt-repository ppa:paulo-miguel-dias/pkppa -y
			apt update
			apt dist-upgrade -y

			dpkg --add-architecture i386
			apt update
			apt install mesa-vulkan-drivers mesa-vulkan-drivers:i386 -y
			;;
		none)
			echo "GPU not detected."
			;;
		*)
			echo "Skipping GPU driver installation."
			;;
	esac
fi

# Install steam and steam device support.
if [ ! -e /usr/games/steam ]; then
	echo "Installing steam..."
	apt update
	apt install steam steam-devices x11-utils -y
fi

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

# (Re-)install conf files from this repo
if [[ "${UPDATE_CONFFILES}" == "true" ]]; then
	echo "(Re-)Installing System Config"
	# Enable automatic login. We use 'envsubst' to replace the user with ${STEAM_USER}.
	echo "Enabling automatic login..."
	envsubst < ./conf/custom.conf > /etc/gdm3/custom.conf

	# Create our session switching scripts to allow rebooting to the desktop
	echo "Creating reboot to session scripts..."
	envsubst < ./conf/reboot-to-desktop-mode.sh > /usr/local/sbin/reboot-to-desktop-mode
	envsubst < ./conf/reboot-to-steamos-mode.sh > /usr/local/sbin/reboot-to-steamos-mode
	chmod +x /usr/local/sbin/reboot-to-desktop-mode
	chmod +x /usr/local/sbin/reboot-to-steamos-mode

	# Create the "steamos-fg" script as a workaround for games like Deadcells with the Steam compositor.
	cp ./conf/steamos-fg.sh /usr/local/sbin/steamos-fg
	chmod +x /usr/local/sbin/steamos-fg

	# Create a sudoers rule to allow passwordless reboots between sessions.
	echo "Creating sudoers rules to allow rebooting between sessions..."
	cp ./conf/reboot-sudoers.conf /etc/sudoers.d/steamos-reboot
	chmod 440 /etc/sudoers.d/steamos-reboot

	# install steam plymouth theme
	if [ ! -e /usr/share/plymouth/themes/steamos ]; then
		echo "Configuring the SteamOS boot themes..."
		if [ ! -e plymouth-themes-steamos_${STEAMOS_PLYMOUTH_VER}.deb ]; then
			set -e
			wget "http://repo.steampowered.com/steamos/pool/main/p/plymouth-themes-steamos/plymouth-themes-steamos_${STEAMOS_PLYMOUTH_VER}.deb"
			set +e
		fi
		dpkg -i plymouth-themes-steamos_${STEAMOS_PLYMOUTH_VER}.deb
		apt install --fix-broken --assume-yes

		# also see /usr/bin/steamos/update_plymouth_branding.sh
		update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/steamos/steamos.plymouth 100
		update-alternatives --set default.plymouth /usr/share/plymouth/themes/steamos/steamos.plymouth

		# Update the grub theme.
		GRUB_BACKGROUND_LINE='GRUB_BACKGROUND=/usr/share/plymouth/themes/steamos/steamos_branded.png'
		if grep '^GRUB_BACKGROUND=' /etc/default/grub; then

			sed -i "s@^GRUB_BACKGROUND=.*@${GRUB_BACKGROUND_LINE}@" /etc/default/grub
		else
			echo 'GRUB_BACKGROUND=/usr/share/plymouth/themes/steamos/steamos_branded.png' >> /etc/default/grub
		fi
		update-grub
	fi

	# Set the X session to use the installed steamos session
	if [ ! -e /usr/share/xsessions/steamos.desktop ]; then
		echo "Installing SteamOS Compositor..."
		if [ ! -e steamos-compositor_${STEAMOS_COMPOSITOR_VER}.deb ]; then
			set -e
			wget "http://repo.steampowered.com/steamos/pool/main/s/steamos-compositor/steamos-compositor_${STEAMOS_COMPOSITOR_VER}.deb"
			set +e
		fi
		dpkg -i steamos-compositor_${STEAMOS_COMPOSITOR_VER}.deb
		apt install --fix-broken --assume-yes
	fi
	echo "Configuring the default session..."
	cp ./conf/steam-session.conf "/var/lib/AccountsService/users/${STEAM_USER}"

	# Install Mode Switch (requires i386 architecture)
	if [ ! -e /usr/lib/x86_64-linux-gnu/libmodeswitch_inhibitor.so.0.0.0 ]; then
		echo "Installing SteamOS ModeSwitch..."
		if [ ! -e steamos-modeswitch-inhibitor_${STEAMOS_MODESWITCH_VER}.deb ]; then
			set -e
			wget "http://repo.steampowered.com/steamos/pool/main/s/steamos-modeswitch-inhibitor/steamos-modeswitch-inhibitor_${STEAMOS_MODESWITCH_VER}.deb"
			set +e
		fi
		dpkg --add-architecture i386
		apt update
		dpkg -i steamos-modeswitch-inhibitor_${STEAMOS_MODESWITCH_VER}.deb
		apt install --fix-broken --assume-yes
	fi
fi

echo
echo "Installation complete!"
echo
echo "You should run steam in desktop mode once to update and enable SteamPlay in settings."
echo "Press [ENTER] to reboot or [CTRL]+C to exit"
read -r
reboot-to-desktop-mode
