Cmnd_Alias DESKTOP = /usr/local/sbin/reboot-to-desktop-mode
Cmnd_Alias STEAMOS = /usr/local/sbin/reboot-to-steamos-mode

%sudo ALL = (root) NOPASSWD:DESKTOP,STEAMOS
%admin ALL = (root) NOPASSWD:DESKTOP,STEAMOS

Cmnd_Alias REBOOT = /sbin/reboot
Cmnd_Alias SED = /bin/sed

%sudo ALL = (root) NOPASSWD:REBOOT,SED
%admin ALL = (root) NOPASSWD:REBOOT,SED
