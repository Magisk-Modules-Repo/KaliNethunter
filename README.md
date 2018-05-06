# Kali Nethunter for Magisk

This module allows you to install the Kali Nethunter chroot systemlessly - see https://github.com/offensive-security/kali-nethunter for further information about kali Nethunter
![Kali NetHunter](https://raw.githubusercontent.com/offensive-security/kali-nethunter/master/images/nethunter-git-logo.png)

## Installation instructions:
* Install attached Magisk Module
* Reboot device
* Run Nethunter app - allow 7(!) Root-related permissions prompts and wait for initialisation
* Click "Kali Chroot Manager"
* Click "Install Kali Chroot" - "Download Latest"
* Install the full Chroot Kali package (around 800MB)
* Wait for Chroot to downlaod/install (this may take a few minutes)
* Click "Install & Update" - allow Root permission for Nethunter Terminal app
* Enjoy!

## Not Working:
Anything which requires the custom kernel/ramdisk will not work out of the box. This includes:
* Wi-Fi injection (requires custom kernel/ramdisk)
* HID Interfaces (BadUSB/Duckhunter etc. - also requires custom kernel/ramdisk)

## Uninstall:
To remove this fully:
* Load "Kali Chroot Manager" in the Nethunter app and click "Remove Chroot" (Reboot and Remove Chroot)
* Uninstall Kali Nethunter Magisk module (Reboot)
* Manually uninstall Nethunter, Kali Terminal and Kali VNC apps
* Remove any leftover files - /sdcard/nh_files, /sdcard/nh_install_*.log

## Notes
This is an unofficial build. Credits to all the Offensive Security team and those working on the Nethunter project.
