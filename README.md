# SteamOS Ubuntu

![SteamOS Ubuntu](image.png)

SteamOS Ubuntu is a set of scripts to create an Ubuntu-based Steam machine.

It will do the following:

* Create the `steam` user account if it does not exist.
* Install steam, if it is not installed.
* Install the Steam Compositor, Steam Mode Switch, and boot splash themes.
* Configure autologin for the `steam` user account.
* Configure the default session to the Steam Compositor.
* Create `reboot-to-[steamos,desktop]-mode` scripts to switch between sessions.

For best results, this should be run on a fresh installation of
Ubuntu 18.04 desktop.

## Installation

Installation is very simple. Follow these steps to install SteamOS Ubuntu:

1. Clone or download this repository:    
`git clone https://github.com/ShadowApex/steamos-ubuntu.git`

2. Run the installation script:    
`cd steamos-ubuntu`    
`sudo ./install.sh`

## Switching between sessions

After installation, there will not be an easy way to switch between a regular
Gnome desktop session and Steam. In order to make it easier to switch between
the two, there are two commands that are installed that will let you switch 
between the two:

* `reboot-to-desktop-mode` - sets gnome as the default session and reboots
* `reboot-to-steamos-mode` - sets steam as the default session and reboots

You can access the terminal from Steam by adding a local shortcut for `Sakura`.
