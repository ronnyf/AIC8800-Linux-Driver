# AIC8800 Linux Driver

AIC8800 WiFi driver for AIC8800D80/AIC8800DC/AIC8800DW chips, tested on CachyOS Linux (Arch-based).

## Overview

This driver provides fullmac WiFi support for AIC8800 series chips on Linux kernels 6.0 through 7.2.
Tested and verified on kernel 6.19.10 with LLVM/Clang compilation.

Kernel 7.3 is **not** supported yet. Upstream converted the cfg80211 `cookie`
from an output to a pre-assigned input parameter, which changes the behaviour of
`.remain_on_channel` and `.mgmt_tx` rather than just their signatures, and
removed `.probe_client` from `struct cfg80211_ops` altogether. This driver
implements all three.

## Test Environment

- **Platform**: CachyOS Linux (Arch-based)
- **Kernel Version**: Linux 6.19.10-1-cachyos
- **Compiler**: LLVM/Clang 22.1.2
- **Architecture**: x86_64
- **USB Interface**: AIC8800D80 USB WiFi adapter

Every pull request is additionally compiled in CI against the current Arch
`linux-headers` and `linux-lts-headers`, the Arch testing headers, and an
upstream v7.2 tree built twice — once with gcc, once with clang. The upstream
jobs are the ones that actually exercise the 7.2-specific code paths, since Arch
does not package 7.2 yet, and they are also the only ones that compile the
wireless-extensions path against 7.2.

## Acknowledgments

This project references the following resources:

- [Official Ugreen AX300 Driver](https://www.ugreen.com/)
- Code modifications assisted by OpenCode AI assistant and mlx-community/Qwen3-Coder-Next-8bit

## Recent Updates

- **2026.08.26**: Kernel 7.2 build support (`strncpy` removal, `.remain_on_channel` gained `rx_addr`), CI now compiles every PR
- **2026.04.03**: Updated for kernel 6.19.10, verified LLVM compilation, added production configuration
- **2025.11.11**: Linux Kernel 6.17.7-arch1-1 compilation verified

## Installation on Arch Linux / CachyOS (pacman repository)

The recommended route. Add the repository once and updates arrive with a normal
`pacman -Syu`. Append to `/etc/pacman.conf`:

```ini
[aic8800]
SigLevel = Optional TrustAll
Server = https://ronnyf.github.io/AIC8800-Linux-Driver/x86_64
```

Then install, along with the headers matching your kernel:

```bash
sudo pacman -Sy aic8800/aic8800-fdrv-dkms
sudo pacman -S linux-headers          # or linux-cachyos-headers, linux-lts-headers, linux-zen-headers
```

DKMS rebuilds the modules automatically on each kernel update.

> The packages are **not** PGP signed, which is why `SigLevel = Optional TrustAll`
> is required — you are trusting GitHub Pages and this repository's release
> pipeline. If that is not acceptable, build from the `PKGBUILD` attached to a
> [release](https://github.com/ronnyf/AIC8800-Linux-Driver/releases) instead.

## Compilation and Installation

```bash
# Clone the repository
git clone https://github.com/ronnyf/AIC8800-Linux-Driver.git
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

### Firmware for base AIC8800 / AIC8800DC / AIC8800DW (USB)

`fw/aic8800D80` in this repo only covers the D80 chip. A USB adapter that
enumerates as `a69c:8800` (not `a69c:8d80`) is the older base AIC8800/DC/DW
chip instead — check with `lsusb`. On that hardware `aic_load_fw` looks for
`/lib/firmware/aic8800/fmacfw.bin` and fails with `file failed to open` /
`wrong size of firmware file` in `dmesg`, since that directory isn't shipped
here.

Grab the matching firmware set (`fmacfw.bin`, `fw_patch.bin`, `fw_adid.bin`,
`fw_patch_table.bin`, `aic_userconfig.txt`, ...) from
[armbian/firmware](https://github.com/armbian/firmware/tree/master/aic8800/USB/aic8800)
into `/lib/firmware/aic8800/`, then reload the modules:

```bash
sudo mkdir -p /lib/firmware/aic8800
sudo curl -sSL -o /lib/firmware/aic8800/fmacfw.bin \
  https://raw.githubusercontent.com/armbian/firmware/master/aic8800/USB/aic8800/fmacfw.bin
# repeat for fw_patch.bin, fw_adid.bin, fw_patch_table.bin, aic_userconfig.txt
# (fetch the full file list from the armbian/firmware link above)

sudo modprobe -r aic8800_fdrv aic_load_fw
sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv
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
