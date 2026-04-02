# AIC8800 Linux Driver

AIC8800 WiFi driver, suitable for the Arch Linux platform.

## Overview

This driver fixes compilation errors for the AIC8800 chip on Linux Kernel version 6.17.1-arch1-1.
**Update 2025.11.11**: Linux Kernel 6.17.7-arch1-1 still compiles successfully on the Arch Linux x64 platform.

## Test Environment

- **Platform**: Arch Linux
- **Kernel Version**: Linux 6.17.1-arch1-1
- **External Network Card**: Ugreen AX300-CM762

## Acknowledgments

This project references the following resources:

- [Official Ugreen AX300 Driver](https://www.ugreen.com/)
- Adaptation work from the [sqlwwx/aic8800](https://github.com/sqlwwx/aic8800) project
- Code modifications assisted by Codex

## Compilation and Installation

```bash
# Clone the repository
git clone https://github.com/BLUEMOON233/AIC8800-Linux-Driver.git

# Initialization
cd AIC8800-Linux-Driver
sudo su
sh install_setup.sh
cd drivers/aic8800

# Compile
make

# Install
make install

# Load the driver
modprobe cfg80211
modprobe aic_load_fw
modprobe aic8800_fdrv

# Check driver loading status
lsmod | grep aic
```
