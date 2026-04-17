# Fix All Build Warnings

**Date**: 2026-04-17  
**Branch**: `ronnyf/missing-prototype-warnings`  
**Build**: `make -C drivers/aic8800` on kernel 6.19.12-1-cachyos (clang)  
**Status**: Build succeeds, 82 warnings

## Warning Summary

| Category | Count | Fix |
|----------|-------|-----|
| `-Wmissing-prototypes` (local-only) | 37 | Add `static` keyword |
| `-Wmissing-prototypes` (cross-file) | 39 | Add prototype to header |
| `-Wpointer-bool-conversion` | 2 | Fix null check on array member |
| `-Wunused-function` | 3 | Wrap in `#ifdef` or remove |
| `-Wsometimes-uninitialized` | 1 | Initialize variable |
| **Total** | **82** | |

---

## Step 1: Add `static` to Local-Only Functions (37 warnings)

Functions used only within their own .c file — add `static` to the definition.

### aic8800_fdrv/rwnx_rx.c (7 functions)
| Line | Function |
|------|----------|
| 345 | `rwnx_rx_data_skb_resend` |
| 1534 | `reord_flush_tid` |
| 1786 | `reord_rxframes_process` |
| 1822 | `reord_rxframes_ind` |
| 1906 | `reord_process_unit` |
| 2102 | `remove_sec_hdr_mgmt_frame` |
| 2183 | `defrag_timeout_cb` |

### aic8800_fdrv/aicwf_tcp_ack.c (9 functions)
| Line | Function |
|------|----------|
| 18 | `intf_tcp_drop_msg` |
| 31 | `tcp_ack_timeout` |
| 120 | `tcp_check_quick_ack` |
| 213 | `tcp_check_ack` |
| 257 | `tcp_ack_match` |
| 285 | `tcp_ack_update` |
| 310 | `tcp_ack_alloc_index` |
| 349 | `tcp_ack_handle` |
| 436 | `tcp_ack_handle_new` |

### aic8800_fdrv/aic_priv_cmd.c (4 functions)
| Line | Function |
|------|----------|
| 233 | `command_strtoul` |
| 266 | `str_starts` |
| 1612 | `handle_private_cmd` |
| 1726 | `set_mon_chan` |

### aic8800_fdrv/rwnx_platform.c (2 functions)
| Line | Function |
|------|----------|
| 2343 | `rwnx_plat_nvram_set_value` |
| 2649 | `rwnx_plat_nvram_set_value_8800d80x2` |

### aic8800_fdrv/rwnx_radar.c (2 functions)
| Line | Function |
|------|----------|
| 903 | `pri_detector_init` |
| 1072 | `print_radar_detect_info` |

### aic8800_fdrv/aic_vendor.c (2 functions)
| Line | Function |
|------|----------|
| 41 | `aic_dev_start_mkeep_alive` |
| 69 | `aic_dev_stop_mkeep_alive` |

### aic8800_fdrv/aicwf_wext_linux.c (2 functions)
| Line | Function |
|------|----------|
| 717 | `aic_get_sec_ie` |
| 830 | `aicwf_get_is_wps_ie` |

### aic8800_fdrv/aicwf_compat_8800dc.c (2 functions)
| Line | Function |
|------|----------|
| 2633 | `aicwf_patch_var_config_8800dc` |
| 3553 | `set_bbpll_config` |

### aic8800_fdrv/rwnx_dini.c (2 functions)
| Line | Function |
|------|----------|
| 105 | `rwnx_cfpga_irq_enable` |
| 129 | `rwnx_cfpga_irq_disable` |

### aic8800_fdrv/rwnx_mod_params.c (1 function)
| Line | Function |
|------|----------|
| 270 | `rwnx_get_countrycode_channels` |

### aic8800_fdrv/usb_host.c (1 function)
| Line | Function |
|------|----------|
| 35 | `aicwf_usb_host_txdesc_get` |

### aic8800_fdrv/aicwf_txrxif.c (1 function)
| Line | Function |
|------|----------|
| 1300 | `rxbuff_queue_penq` |

### aic8800_fdrv/aicwf_usb.c (2 functions)
| Line | Function |
|------|----------|
| 158 | `rwnx_stop_sta_all_queues` |
| 168 | `rwnx_wake_sta_all_queues` |

### aic_load_fw/aicbluetooth.c (2 functions)
| Line | Function |
|------|----------|
| 259 | `aic_crc32` |
| 1012 | `rwnx_plat_userconfig_set_value` |

---

## Step 2: Add Header Prototypes for Cross-File Functions (39 warnings)

Functions called from other .c files — add `extern` prototypes to the appropriate header.

### aic_load_fw/aicbluetooth.c → aicbluetooth.h (11 functions)
| Line | Function |
|------|----------|
| 900 | `get_fw_path` |
| 908 | `set_testmode` |
| 912 | `get_testmode` |
| 916 | `get_hardware_info` |
| 921 | `get_adap_test` |
| 925 | `get_flash_bin_size` |
| 930 | `get_flash_bin_crc` |
| 949 | `get_userconfig_xtal_cap` |
| 962 | `get_userconfig_txpwr_idx` |
| 989 | `get_userconfig_txpwr_ofst` |
| 1060 | `rwnx_plat_userconfig_parsing` |

### aic_load_fw/aicwf_usb.c → aicwf_usb.h (2 functions)
| Line | Function |
|------|----------|
| 1379 | `aicfw_download_fw_8800` |
| 1654 | `aicfw_download_fw` |

### aic_load_fw/aicwf_txq_prealloc.c → aicwf_txq_prealloc.h (2 functions)
| Line | Function |
|------|----------|
| 13 | `aicwf_prealloc_txq_alloc` |
| 50 | `aicwf_prealloc_txq_free` |

### aic8800_fdrv/rwnx_irqs.c → rwnx_irqs.h or rwnx_main.h (2 functions)
| Line | Function |
|------|----------|
| 21 | `rwnx_irq_hdlr` |
| 34 | `rwnx_task` |

### aic8800_fdrv/rwnx_utils.c → rwnx_utils.h or rwnx_main.h (1 function)
| Line | Function |
|------|----------|
| 23 | `rwnx_init_aic` |

### aic8800_fdrv/rwnx_cmds.c → rwnx_cmds.h (1 function)
| Line | Function |
|------|----------|
| 345 | `cmd_mgr_task_process` |

### aic8800_fdrv/rwnx_platform.c → rwnx_platform.h (7 functions)
| Line | Function |
|------|----------|
| 762 | `rwnx_request_firmware_common` |
| 773 | `rwnx_release_firmware_common` |
| 790 | `rwnx_plat_bin_fw_upload_2` |
| 1959 | `rwnx_atoi2` |
| 1986 | `rwnx_atoi` |
| 2334 | `get_userconfig_xtal_cap` |
| 2872 | `rwnx_plat_userconfig_parsing_8800d80x2` |

### aic8800_fdrv/rwnx_msg_rx.c → rwnx_msg_rx.h or rwnx_main.h (2 functions)
| Line | Function |
|------|----------|
| 1661 | `rwnx_rx_handle_msg` |
| 1673 | `rwnx_rx_handle_print` |

### aic8800_fdrv/rwnx_pci.c → rwnx_pci.h (2 functions)
| Line | Function |
|------|----------|
| 85 | `rwnx_pci_register_drv` |
| 90 | `rwnx_pci_unregister_drv` |

### aic8800_fdrv/aic_vendor.c → aic_vendor.h (1 function)
| Line | Function |
|------|----------|
| 1064 | `aicwf_vendor_init` |

### aic8800_fdrv/rwnx_main.c (already fixed — verify header prototype)
| Line | Function |
|------|----------|
| 556 | `rwnx_skb_align_8bytes` — needs prototype in header (currently only forward-declared in rwnx_rx.c) |

### aic8800_fdrv/aicwf_compat_8800d80.c → aicwf_compat_8800d80.h or rwnx_platform.h (2 functions)
| Line | Function |
|------|----------|
| 16 | `aicwf_set_rf_config_8800d80` |
| 36 | `rwnx_plat_userconfig_load_8800d80` |

### aic8800_fdrv/aicwf_compat_8800d80x2.c → aicwf_compat_8800d80x2.h or rwnx_platform.h (2 functions)
| Line | Function |
|------|----------|
| 17 | `aicwf_set_rf_config_8800d80x2` |
| 37 | `rwnx_plat_userconfig_load_8800d80x2` |

### aic8800_fdrv/aicwf_usb.c → aicwf_usb.h (1 function)
| Line | Function |
|------|----------|
| 1963 | `aicwf_usb_cancel_all_urbs` |

---

## Step 3: Fix Pointer-Bool-Conversion Warnings (2 warnings)

**File**: `aic8800_fdrv/rwnx_msg_rx.c`

`bssid` is an array member inside a struct, so `!bss->bssid` always evaluates to `true` (address of array is never NULL).

| Line | Current Code | Fix |
|------|-------------|-----|
| 792 | `if (!bss \|\| !bss->bssid)` | `if (!bss)` — remove array address check |
| 797 | `if (!scan_re_wext \|\| !scan_re_wext->bss \|\| !scan_re_wext->bss->bssid)` | Remove the `!...->bssid` part |

---

## Step 4: Fix Unused Function Warnings (3 warnings)

**File**: `aic8800_fdrv/rwnx_main.c`

| Line | Function | Action |
|------|----------|--------|
| 623 | `rwnx_frame_parser` | Remove (dead code) or wrap in `#ifdef CONFIG_RWNX_DBG` |
| 4256 | `rwnx_cfg80211_mgmt_frame_register` | Check kernel version guard — likely needs `#if` for older kernels |
| 8511 | `aic_ipc_setting` | Remove (dead code) or wrap in appropriate `#ifdef` |

---

## Step 5: Fix Uninitialized Variable Warning (1 warning)

**File**: `aic8800_fdrv/aicwf_usb.c`

| Line | Issue | Fix |
|------|-------|-----|
| 1736 | `u8 *buf_align;` uninitialized | Change to `u8 *buf_align = NULL;` |

The variable is used at line 1853 but only assigned inside an `if` block at line 1843. If the condition is false, `buf_align` is used uninitialized.

---

## Execution Order

1. **Step 1** first — simple `static` additions, 37 warnings, no risk of breakage
2. **Step 5** next — trivial one-liner
3. **Step 3** next — simple logic fix, 2 warnings
4. **Step 4** next — remove/guard unused functions, 3 warnings
5. **Step 2** last — header prototype additions require identifying correct headers and verifying includes, highest complexity

## Verification

After each step, build on Linux target:
```bash
make -C drivers/aic8800 2>&1 | grep -c 'warning:'
```

Expected: 82 → 45 → 44 → 42 → 39 → 0
