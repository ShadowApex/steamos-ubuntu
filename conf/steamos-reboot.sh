Cmnd_Alias reboot_desktop = /usr/local/sbin/reboot-to-desktop-mode
Cmnd_Alias reboot_steamos = /usr/local/sbin/reboot-to-steamos-mode

ALL ALL = NOPASSWD:reboot_desktop
ALL ALL = NOPASSWD:reboot_steamos