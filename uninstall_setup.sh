#!/bin/bash
################################################################################
#			clean files
################################################################################
echo "WARNING: uninstall_setup.sh is DEPRECATED and will be removed."
echo "Use 'make uninstall' (or modular targets: uninstall_firmware, uninstall_rules, uninstall_modules)"
echo ""
echo "Clean aic8800 wifi driver setup files (legacy)!"
echo "Authentication requested [root] for clean:"
if [ "`uname -r |grep fc`" == " " ]; then
	  sudo su -c "rm -rf /lib/firmware/aic8800D80/"; Error=$?
	  sudo su -c "rm /etc/udev/rules.d/aic.rules"; Error=$?
	  sudo su -c "udevadm control --reload"; Error=$?
else
	  su -c "rm -rf /lib/firmware/aic8800D80/"; Error=$?
	  su -c "rm /etc/udev/rules.d/aic.rules"; Error=$?
	  su -c "udevadm control --reload"; Error=$?
fi

echo "The Uninstall Setup Script is completed!"
