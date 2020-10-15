#!/bin/bash

# Set the defaults. These can be overridden by specifying the value as an
# environment variable when running this script.
STEAM_USER="${STEAM_USER:-steam}"

# This is to run steam as steam_user to change configurations such as proton

echo "Starting Steam as: ${STEAM_USER}"
sudo -i -u ${STEAM_USER} pkill steam 
sudo -i -u ${STEAM_USER} /usr/games/steam
