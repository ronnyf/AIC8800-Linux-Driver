#!/bin/bash

echo "WARNING: install_setup.sh is DEPRECATED and will be removed."
echo "Use 'make install' (or modular targets: install_firmware, install_rules, install_modules)"
echo ""
echo "##################################################"
echo "AIC Wi-Fi driver Setup Files script (legacy)"
echo "2023.03.09 v1.1.0 - DEPRECATED"
echo "##################################################"

Main_version=`uname -r |awk -F'.' '{print $1}'`
Minor_version=`uname -r |awk -F'.' '{print $2}'`

echo "Authentication requested [root] for setup:"
if [ "`uname -r |grep fc`" == " " ]; then
	sudo su -c "cp -rf ./fw/aic8800D80 /lib/firmware/"; Error=$?
	sudo su -c "cp ./tools/aic.rules /etc/udev/rules.d"; Error=$?
    sudo su -c "udevadm trigger"; Error=$?
	sudo su -c "udevadm control --reload"; Error=$?
	if [ -L /dev/aicudisk ]; then
		sudo su -c "eject /dev/aicudisk"; Error=$?
	fi
else
	su -c "cp -rf ./fw/aic8800D80 /lib/firmware/"; Error=$?
	su -c "cp ./tools/aic.rules /etc/udev/rules.d"; Error=$?
    su -c "udevadm trigger"; Error=$?
	su -c "udevadm control --reload"; Error=$?
	if [ -L /dev/aicudisk ]; then
		su -c "eject /dev/aicudisk"; Error=$?
	fi
fi

echo "##################################################"
echo "The Setup Script is completed !"
echo "##################################################"
