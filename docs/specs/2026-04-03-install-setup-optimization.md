# Install Setup Optimization Design

**Date:** 2026-04-03

## Overview

Replace the legacy bash scripts `install_setup.sh` and `uninstall_setup.sh` with Makefile-based installation targets that provide better error handling, batching, and idempotency.

## Current State

### `install_setup.sh`
- Copies firmware from `./fw/aic8800D80` to `/lib/firmware`
- Copies udev rules from `./tools/aic.rules` to `/etc/udev/rules.d`
- Triggers udev reload
- Handles aicudisk eject

### `uninstall_setup.sh`
- Removes firmware directory `/lib/firmware/aic8800D80`
- Removes udev rules `/etc/udev/rules.d/aic.rules`
- Reloads udev rules

## Problems

1. **Error handling ignored** - Sets `Error=$?` but never checks
2. **Distro detection fragile** - `grep fc` for Fedora detection is unreliable
3. **Inefficient** - Multiple `sudo su -c` calls instead of batching
4. **Not idempotent** - No checks before copy/delete
5. **Hardcoded paths** - No configuration flexibility

## Solution

### New Makefile Targets

```makefile
# Variables for install-setup
FIRMWARE_PATH ?= ./fw/aic8800D80
FIRMWARE_DEST ?= /lib/firmware
UDEV_RULES_SRC ?= ./tools/aic.rules
UDEV_RULES_DEST ?= /etc/udev/rules.d

install-setup:
	@test -d $(FIRMWARE_PATH) || { echo "ERROR: Firmware directory not found" >&2; exit 1; }
	@test -f $(UDEV_RULES_SRC) || { echo "ERROR: Udev rules file not found" >&2; exit 1; }
	@sudo su -c ". $(CURDIR)/install-setup-script.sh ..."
	@echo "Firmware and udev rules installed successfully!"

uninstall-setup:
	@sudo su -c ". $(CURDIR)/uninstall-setup-script.sh ..."
	@echo "Firmware and udev rules uninstalled successfully!"
```

### Helper Scripts

**`install-setup-script.sh`**
- Single root command with all operations
- Strict error handling with `set -e`
- Check source exists before copy

**`uninstall-setup-script.sh`**
- Idempotent delete (check before rm)
- Reload udev after cleanup

### Legacy Scripts

Mark both `install_setup.sh` and `uninstall_setup.sh` as deprecated with warning messages redirecting to Makefile.

## Benefits

1. **Better error handling** - Fail fast on errors
2. **Batched root operations** - Single sudo per operation
3. **Idempotent operations** - Check before copy/delete
4. **Configurable paths** - Variables for customization
5. **Clearer separation** - Module installation separate from firmware setup

## Files Changed

1. `drivers/aic8800/Makefile` - Add new targets
2. `drivers/aic8800/install-setup-script.sh` - New helper
3. `drivers/aic8800/uninstall-setup-script.sh` - New helper
4. `drivers/aic8800/aic8800_fdrv/AGENTS.md` - Update documentation
5. `install_setup.sh` - Mark deprecated
6. `uninstall_setup.sh` - Mark deprecated

## Testing

1. Clean build: `make -C drivers/aic8800 clean`
2. Build kernel: `make LLVM=1 -C drivers/aic8800`
3. Install modules: `make -C drivers/aic8800 install`
4. Install setup: `make -C drivers/aic8800 install-setup`
5. Uninstall setup: `make -C drivers/aic8800 uninstall-setup`
6. Uninstall modules: `make -C drivers/aic8800 uninstall`