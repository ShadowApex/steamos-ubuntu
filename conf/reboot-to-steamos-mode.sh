#!/bin/bash

# Set the X session to the steamos session and reboot
/usr/bin/sudo /bin/sed -i  's/XSession.*/XSession=steamos/g' /var/lib/AccountsService/users/$STEAM_USER
/usr/bin/sudo /sbin/reboot
