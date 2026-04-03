# AIC8800 Linux Driver

AIC8800 WiFi driver for AIC8800D80/AIC8800DC/AIC8800DW chips, tested on CachyOS Linux (Arch-based).

## Overview

This driver provides fullmac WiFi support for AIC8800 series chips on Linux kernels 6.0+.
Tested and verified on kernel 6.19.10 with LLVM/Clang compilation.

## Test Environment

- **Platform**: CachyOS Linux (Arch-based)
- **Kernel Version**: Linux 6.19.10-1-cachyos
- **Compiler**: LLVM/Clang 22.1.2
- **Architecture**: x86_64
- **USB Interface**: AIC8800D80 USB WiFi adapter

## Acknowledgments

This project references the following resources:

- [Official Ugreen AX300 Driver](https://www.ugreen.com/)
- Code modifications assisted by OpenCode AI assistant and mlx-community/Qwen3-Coder-Next-8bit

## Recent Updates

- **2026.04.03**: Updated for kernel 6.19.10, verified LLVM compilation, added production configuration
- **2025.11.11**: Linux Kernel 6.17.7-arch1-1 compilation verified

## Compilation and Installation

```bash
# Clone the repository
git clone https://github.com/BLUEMOON233/AIC8800-Linux-Driver.git
cd AIC8800-Linux-Driver

# Compile with LLVM/Clang
make LLVM=1 -C drivers/aic8800

# Install modules and firmware
make -C drivers/aic8800 install

# Load the driver
sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv

# Check driver loading status
lsmod | grep aic

# Verify WiFi interface
iwconfig
```

## Configuration

The driver is configured for production use with the following key settings:

- **FullMAC mode**: Enabled (`CONFIG_RWNX_FULLMAC=y`)
- **USB support**: Enabled (`CONFIG_USB_SUPPORT=y`)
- **5GHz band**: Enabled (`CONFIG_USE_5G=y`)
- **DPD calibration**: Enabled (`CONFIG_DPD=y`)
- **MCC support**: Enabled (`CONFIG_MCC=y`)
- **Debugging**: Disabled for production (`CONFIG_RWNX_DBG=n`, `CONFIG_DEBUG_FS=n`)

## Supported Features

- 2.4GHz / 5GHz dual-band WiFi
- 802.11ax (WiFi 6) support
- USB 2.0/3.0 interface
- WPA3 security
- MU-MIMO (firmware dependent)
- Beamforming (firmware dependent)

## Platform Support

| Platform | CONFIG_PLATFORM_* | Status |
|----------|-------------------|--------|
| CachyOS/Arch | `CONFIG_PLATFORM_UBUNTU=y` | ✓ Tested |
| Ubuntu/Debian | `CONFIG_PLATFORM_UBUNTU=y` | ✓ Supported |
| Rockchip | `CONFIG_PLATFORM_ROCKCHIP=y` | ✓ Supported |
| Allwinner | `CONFIG_PLATFORM_ALLWINNER=y` | ✓ Supported |
| Amlogic | `CONFIG_PLATFORM_AMLOGIC=y` | ✓ Supported |
