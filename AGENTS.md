# AIC8800 Linux Driver - Agent Guidelines

## Build System

**Compile**: `make LLVM=1 -C drivers/aic8800`  
**Install/Clean/Uninstall**: `make -C drivers/aic8800 {install,clean,uninstall}`

**Platform configs**: `CONFIG_PLATFORM_ROCKCHIP` (arm64), `CONFIG_PLATFORM_ALLWINNER` (arm64), `CONFIG_PLATFORM_AMLOGIC` (arm), `CONFIG_PLATFORM_HI` (arm), `CONFIG_PLATFORM_UBUNTU` (default)

## Code Style

- Linux kernel style (8-space tabs, 80-char lines)
- `.h` files: declarations; `.c` files: implementations
- License: `Copyright (C) RivieraWaves 2012-2019`
- Kernel-doc: `/** ... */`
- Names: `rwnx_*` (core), `aicwf_*` (wifi)
- Include order: `<linux/.>`, `<net/.>`, `"rwnx_*.h"`, `"aicwf_*.h"`, `"reg_*.h"`

## Naming

- Types: `rwnx_*_t` (e.g., `rwnx_hw`, `rwnx_sta`)  
- Functions: `rwnx_*`, `aicwf_*`  
- Constants: `RWNX_*`, `AICWF_*`  
- Globals: `aic_fw_path`, `country_code`

## Error Handling

- Return negative errno (`-ENOMEM`, `-EINVAL`, `-1`)
- `RWNX_DBG(LOGDEBUG/LOGINFO/LOGERROR, ...)`  
- `printk(KERN_CRIT ...)` for critical errors  
- Validate firmware file size > 0

## Preprocessor

- `#ifdef CONFIG_*` for Kconfig  
- `#if LINUX_VERSION_CODE >= KERNEL_VERSION(...)` for version checks  
- Headers: `#ifndef _NAME_H_` / `#define _NAME_H_` / `#endif`

## Types

```c
u8, u16, u32, u64, s8, s16, s32, s64  // <linux/types.h>
bool                                  // Linux kernel
```

## Memory/Thread Safety

- `kzalloc()` / `kfree()`  
- `skb_queue_len()`, `skb_queue_walk()`  
- `spin_lock_bh()` / `spin_unlock_bh()`  
- `tasklet_schedule()`, `tx_lock` spinlock

## Module Config

Key options: `CONFIG_AIC8800_WLAN_SUPPORT=m`, `CONFIG_USB_SUPPORT=y`, `CONFIG_SDIO_SUPPORT=n`, `CONFIG_RWNX_FULLMAC=y`, `CONFIG_RWNX_SDM=n`, `CONFIG_RWNX_TL4=n`, `CONFIG_DEBUG_FS=n`, `CONFIG_RWNX_DBG=y`

## Kconfig Location

- `drivers/aic8800/Kconfig`  
- `drivers/aic8800/aic8800_fdrv/Kconfig`  
- `drivers/aic8800/aic_load_fw/Kconfig`

## File Organization

```
drivers/aic8800/
├── aic8800_fdrv/   # WiFi driver (rwnx_*.c, aicwf_*.c)
├── aic_load_fw/    # Firmware (aicbluetooth_*.c, aicwf_*.c)
└── Makefile
```

Key files: `rwnx_main.c`, `rwnx_tx.c/rwnx_rx.c`, `rwnx_msg_tx.c/rwnx_msg_rx.c`, `rwnx_cmds.c`, `rwnx_cfgfile.c`, `aicwf_compat_*.c`

## Kernel Compatibility

- Tested: Arch Linux kernel 6.17.1-arch1-1  
- Compatibility macros in `rwnx_compat.h`/`rwnx_defs.h`  
  `HIGH_KERNEL_VERSION=KERNEL_VERSION(6,0,0)`  
  `HIGH_KERNEL_VERSION2=KERNEL_VERSION(6,1,0)`  
  `HIGH_KERNEL_VERSION3=KERNEL_VERSION(6,3,0)`  
  `HIGH_KERNEL_VERSION4=KERNEL_VERSION(6,3,0)`  
  On Android: `HIGH_KERNEL_VERSION=KERNEL_VERSION(5,15,41)`

## Debugging

- `RWNX_DBG(LOGDEBUG/LOGINFO/LOGERROR, ...)`  
- `AICWFDBG(level, fmt, ...)`  
- `printk()`  
- Enable: `CONFIG_RWNX_DBG=y`

## Common Commands

```bash
modprobe cfg80211 aic_load_fw aic8800_fdrv
lsmod | grep aic
dmesg | tail -20
```

## Platform Notes

**USB**: `CONFIG_USB_SUPPORT=y`, interfaces: `usb_host.c`, `aicwf_usb.c`  
**SDIO**: `CONFIG_SDIO_SUPPORT=n`, interfaces: `sdio_host.c`, `aicwf_sdio.c`  
**Firmware**: `/vendor/etc/firmware` (Android) or `/lib/firmware/`, files: `aic_userconfig_8800d80.txt`, `aic_powerlimit_8800d80.txt`

## Special Considerations

- Alignment: `CONFIG_ALIGN_8BYTES`, `CONFIG_USB_ALIGN_DATA`  
- Power: `CONFIG_WOWLAN=n`, `CONFIG_GPIO_WAKEUP=n`  
- Features: `CONFIG_BAND_STEERING=n`, `CONFIG_RWNX_BFMER` controls MU-MIMO, `CONFIG_RWNX_RADAR=y`  
- Compatibility: `CONFIG_USE_WIRELESS_EXT=y`, `CONFIG_BR_SUPPORT=n`
