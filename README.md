# Fork
- Add support fork kernel 7.x
- Add support for https://www.tunisianet.com.tn/cle-wifi-bluetooth/94539-adaptateur-hikvision-ds-3wru9x-h-usb-wi-fi-6-noir.html

# AIC8800 Linux Driver

AIC8800 WiFi driver for AIC8800D80/AIC8800DC/AIC8800DW chips, tested on CachyOS Linux (Arch-based).

## Overview

This driver provides fullmac WiFi support for AIC8800 series chips on Linux kernels 6.0 through 7.3.
Tested and verified on kernel 6.19.10 with LLVM/Clang compilation.

Kernel 7.3 turned the cfg80211 `cookie` from an output parameter into a
pre-assigned input, which changes the behaviour of `.remain_on_channel` and
`.mgmt_tx` rather than just their signatures, renamed `.probe_client` to
`.probe_peer`, and added a `link_id` argument to `cfg80211_probe_status()`.
The driver stores the pre-assigned cookie and reports it back on RoC
ready/expiry and on management-frame confirmation, so cfg80211's
pending-request matching works on 7.3 as well.

## Test Environment

- **Platform**: CachyOS Linux (Arch-based)
- **Kernel Version**: Linux 6.19.10-1-cachyos
- **Compiler**: LLVM/Clang 22.1.2
- **Architecture**: x86_64
- **USB Interface**: AIC8800D80 USB WiFi adapter

Every pull request is additionally compiled in CI against the current Arch
`linux-headers` and `linux-lts-headers`, the Arch testing headers, and
upstream v7.2 and v7.3 trees built twice — once with gcc, once with clang.
The upstream jobs are the ones that actually exercise the newest
version-guarded code paths (>= 7.2 and >= 7.3), since the packaged kernels in
the other jobs lag upstream, and they are also the only ones that compile the
wireless-extensions path against those kernels.

## Acknowledgments

This project references the following resources:

- [Official Ugreen AX300 Driver](https://www.ugreen.com/)
- Code modifications assisted by OpenCode AI assistant with mlx-community/Qwen3-Coder-Next-8bit and Qwen3.8 27B Splash (via LM Studio)

## Recent Updates

- **2026.11.07**: Kernel 7.3 build support (pre-assigned cfg80211 cookies for `.remain_on_channel`/`.mgmt_tx`, `.probe_peer`, `cfg80211_probe_status` `link_id`), CI now compiles upstream v7.3 as well; version rolled to 6.4.3.1
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

## Installation on Debian / Ubuntu

Download the `.deb` from a
[release](https://github.com/ronnyf/AIC8800-Linux-Driver/releases) and install it:

```bash
curl -LO https://github.com/ronnyf/AIC8800-Linux-Driver/releases/latest/download/aic8800-fdrv-dkms_<version>_all.deb
sudo apt install dkms "linux-headers-$(uname -r)"
sudo dpkg -i aic8800-fdrv-dkms_<version>_all.deb
```

DKMS rebuilds the modules automatically on each kernel update. If the headers
are installed after the package, run `sudo dkms autoinstall`.

> There is no apt repository — the `.deb` is a release asset, so updates are
> manual. `eject` is recommended; the udev rule uses it to switch the dongle out
> of its USB storage mode.

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
