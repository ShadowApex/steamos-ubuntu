#!/bin/bash

# Set the X session to the steamos session and reboot
sudo sed -i  's/XSession.*/XSession=/g' /var/lib/AccountsService/users/$STEAM_USER
sudo reboot
