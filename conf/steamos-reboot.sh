Cmnd_Alias reboot_desktop = /usr/local/sbin/reboot-to-desktop-mode
Cmnd_Alias reboot_steamos = /usr/local/sbin/reboot-to-steamos-mode

ALL ALL = (root) NOPASSWD:reboot_desktop
ALL ALL = (root) NOPASSWD:reboot_steamos
