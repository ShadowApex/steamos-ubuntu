#!/bin/bash

# Get the installed user name
export USER_NAME
USER_NAME=$(grep '.*:x:1000' /etc/passwd | cut -d':' -f1)

# Install steam itself
sudo apt install steam -y

# Download the packages we need
wget http://repo.steamstatic.com/steamos/pool/main/s/steamos-compositor/steamos-compositor_1.34+bsos1_amd64.deb 
wget http://repo.steamstatic.com/steamos/pool/main/s/steamos-modeswitch-inhibitor/steamos-modeswitch-inhibitor_1.10+bsos1_amd64.deb
wget http://repo.steamstatic.com/steamos/pool/main/p/plymouth-themes-steamos/plymouth-themes-steamos_0.17+bsos2_all.deb

# Enable automatic login
envsubst < custom.conf > /etc/gdm3/custom.conf

# Install the steamos compositor, modeswitch, and themes
sudo dpkg -i ./*glob*.deb
sudo apt install -f
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/steamos/steamos.plymouth 100
echo "Please select the steamos theme:"
sudo update-alternatives --config default.plymouth

# Update the grub theme.
echo 'GRUB_BACKGROUND=/usr/share/plymouth/themes/steamos/steamos_branded.png' | sudo tee -a /etc/default/grub
sudo update-grub

# Add support for controllers
# source: https://steamcommunity.com/app/353370/discussions/0/490123197956024380/
sudo cp 99-steam-controller-perms.rules /lib/udev/rules.d/99-steam-controller-perms.rules

echo ""
echo "Installation finished. Reboot to complete the setup."
