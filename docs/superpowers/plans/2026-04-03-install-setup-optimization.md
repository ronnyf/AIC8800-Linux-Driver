# Kernel 6.19 Compatibility + Install Setup Optimization

> **For agentic workers:** Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add kernel 6.19 compatibility fixes (already complete) AND optimize shell scripts by merging install_setup.sh functionality into Makefile install targets

**Architecture:** 
- Add `install-setup` and `uninstall-setup` targets to `drivers/aic8800/Makefile`
- Replace legacy bash scripts with Makefile-based installation
- Improved error handling, batching, and idempotency

**Tech Stack:** Linux kernel 6.19, clang 22.1.2, X86_64

---

## Files to modify

1. `drivers/aic8800/Makefile` - Add install-setup and uninstall-setup targets
2. `install_setup.sh` - Mark as deprecated, redirect to Makefile
3. `uninstall_setup.sh` - Mark as deprecated, redirect to Makefile

---

### Task 1: Add install-setup and uninstall-setup targets to Makefile

**Files:**
- Modify: `drivers/aic8800/Makefile:66-76`

**Steps:**
- [ ] **Step 1: Replace install/uninstall targets with new versions**

At lines 66-76, replace:
```makefile
install:
	mkdir -p $(MODDESTDIR)
	install -p -m 644 aic_load_fw/aic_load_fw.ko  $(MODDESTDIR)/
	install -p -m 644 aic8800_fdrv/aic8800_fdrv.ko  $(MODDESTDIR)/
	/sbin/depmod -a ${KVER}

uninstall:
	rm -rfv $(MODDESTDIR)/aic_load_fw.ko
	rm -rfv $(MODDESTDIR)/aic8800_fdrv.ko
	/sbin/depmod -a ${KVER}
```

To:
```makefile
# Variables for install-setup
FIRMWARE_PATH ?= ./fw/aic8800D80
FIRMWARE_DEST ?= /lib/firmware
UDEV_RULES_SRC ?= ./tools/aic.rules
UDEV_RULES_DEST ?= /etc/udev/rules.d

install:
	mkdir -p $(MODDESTDIR)
	install -p -m 644 aic_load_fw/aic_load_fw.ko  $(MODDESTDIR)/
	install -p -m 644 aic8800_fdrv/aic8800_fdrv.ko  $(MODDESTDIR)/
	/sbin/depmod -a ${KVER}

install-setup:
	@test -d $(FIRMWARE_PATH) || { echo "ERROR: Firmware directory $(FIRMWARE_PATH) not found" >&2; exit 1; }
	@test -f $(UDEV_RULES_SRC) || { echo "ERROR: Udev rules file $(UDEV_RULES_SRC) not found" >&2; exit 1; }
	@echo "##################################################"
	@echo "Installing AIC Wi-Fi firmware and udev rules..."
	@echo "##################################################"
	@sudo su -c ". $(CURDIR)/install-setup-script.sh $(FIRMWARE_PATH) $(FIRMWARE_DEST) $(UDEV_RULES_SRC) $(UDEV_RULES_DEST)" || { echo "ERROR: install-setup failed" >&2; exit 1; }
	@echo "##################################################"
	@echo "Firmware and udev rules installed successfully!"
	@echo "##################################################"

uninstall:
	rm -rfv $(MODDESTDIR)/aic_load_fw.ko
	rm -rfv $(MODDESTDIR)/aic8800_fdrv.ko
	/sbin/depmod -a ${KVER}

uninstall-setup:
	@echo "##################################################"
	@echo "Uninstalling AIC Wi-Fi firmware and udev rules..."
	@echo "##################################################"
	@sudo su -c ". $(CURDIR)/uninstall-setup-script.sh $(FIRMWARE_DEST) $(UDEV_RULES_DEST)" || { echo "ERROR: uninstall-setup failed" >&2; exit 1; }
	@echo "##################################################"
	@echo "Firmware and udev rules uninstalled successfully!"
	@echo "##################################################"
```

- [ ] **Step 2: Create install-setup-script.sh helper**

Create: `drivers/aic8800/install-setup-script.sh`

```bash
#!/bin/bash
set -e

FIRMWARE_PATH="$1"
FIRMWARE_DEST="$2"
UDEV_RULES_SRC="$3"
UDEV_RULES_DEST="$4"

# Install firmware
cp -rf "$FIRMWARE_PATH"/* "$FIRMWARE_DEST"/

# Install udev rules
cp "$UDEV_RULES_SRC" "$UDEV_RULES_DEST"/

# Reload udev rules
udevadm trigger
udevadm control --reload

# Handle aicudisk if exists
if [ -L /dev/aicudisk ]; then
    eject /dev/aicudisk
fi
```

Make it executable: `chmod +x drivers/aic8800/install-setup-script.sh`

- [ ] **Step 3: Create uninstall-setup-script.sh helper**

Create: `drivers/aic8800/uninstall-setup-script.sh`

```bash
#!/bin/bash
set -e

FIRMWARE_DEST="$1"
UDEV_RULES_DEST="$2"

# Remove firmware (only if exists)
if [ -d "$FIRMWARE_DEST/aic8800D80" ]; then
    rm -rf "$FIRMWARE_DEST/aic8800D80"
fi

# Remove udev rules (only if exists)
if [ -f "$UDEV_RULES_DEST/aic.rules" ]; then
    rm "$UDEV_RULES_DEST/aic.rules"
fi

# Reload udev rules
udevadm control --reload
```

Make it executable: `chmod +x drivers/aic8800/uninstall-setup-script.sh`

- [ ] **Step 4: Update AGENTS.md to document new targets**

At line 6 in `AGENTS.md`, change:
```makefile
**Install/Clean/Uninstall**: `make -C drivers/aic8800 {install,clean,uninstall}`
```

To:
```makefile
**Install/Clean/Uninstall**: `make -C drivers/aic8800 {install,install-setup,clean,uninstall,uninstall-setup}`
```

- [ ] **Step 5: Commit changes**

```bash
git add drivers/aic8800/Makefile
git add drivers/aic8800/install-setup-script.sh
git add drivers/aic8800/uninstall-setup-script.sh
git add AGENTS.md
git commit -m "docs: update AGENTS.md to document new install-setup targets"
```

- [ ] **Step 6: Test install-setup**

```bash
make -C drivers/aic8800 install-setup
```

Expected: Firmware and udev rules installed, no errors

- [ ] **Step 7: Test uninstall-setup**

```bash
make -C drivers/aic8800 uninstall-setup
```

Expected: Firmware and udev rules removed, no errors

---

### Task 2: Mark legacy bash scripts as deprecated

**Files:**
- Modify: `install_setup.sh:1-7`
- Modify: `uninstall_setup.sh:1-6`

**Steps:**
- [ ] **Step 1: Mark install_setup.sh as deprecated**

At lines 1-6 in `install_setup.sh`, replace:
```bash
#!/bin/bash

echo "##################################################"
echo "AIC Wi-Fi driver Setup Files script"
echo "2023.03.09 v1.1.0"
echo "##################################################"
```

To:
```bash
#!/bin/bash

echo "WARNING: install_setup.sh is DEPRECATED."
echo "Use 'make install-setup' instead (see drivers/aic8800/Makefile)"
echo ""
echo "##################################################"
echo "AIC Wi-Fi driver Setup Files script (legacy)"
echo "2023.03.09 v1.1.0 - DEPRECATED"
echo "##################################################"
```

- [ ] **Step 2: Mark uninstall_setup.sh as deprecated**

At lines 1-6 in `uninstall_setup.sh`, replace:
```bash
################################################################################
#			clean files
################################################################################
echo "Clean aic8800 wifi driver setup files!"
echo "Authentication requested [root] for clean:"
```

To:
```bash
################################################################################
#			clean files
################################################################################
echo "WARNING: uninstall_setup.sh is DEPRECATED."
echo "Use 'make uninstall-setup' instead (see drivers/aic8800/Makefile)"
echo ""
echo "Clean aic8800 wifi driver setup files (legacy)!"
echo "Authentication requested [root] for clean:"
```

- [ ] **Step 3: Commit changes**

```bash
git add install_setup.sh uninstall_setup.sh
git commit -m "install_setup: mark as deprecated, redirect to Makefile"
```

---

### Task 3: Build verification

**Steps:**
- [ ] **Step 1: Clean build**

```bash
make -C drivers/aic8800 clean
```

- [ ] **Step 2: Build with LLVM**

```bash
make LLVM=1 -C drivers/aic8800
```

Expected: No errors

- [ ] **Step 3: Test install**

```bash
make -C drivers/aic8800 install
```

Expected: Kernel modules installed successfully

- [ ] **Step 4: Test install-setup**

```bash
make -C drivers/aic8800 install-setup
```

Expected: Firmware and udev rules installed

- [ ] **Step 5: Test uninstall-setup**

```bash
make -C drivers/aic8800 uninstall-setup
```

Expected: Firmware and udev rules removed

- [ ] **Step 6: Test uninstall**

```bash
make -C drivers/aic8800 uninstall
```

Expected: Kernel modules removed

- [ ] **Step 7: Commit verification**

```bash
git add .
git commit -m "test: verify install/uninstall targets work correctly"
```

---

## Verification

After all tasks complete:

1. Run build: `make LLVM=1 -C drivers/aic8800` - should pass with 0 errors
2. `make install` - kernel modules installed successfully
3. `make install-setup` - firmware and udev rules installed
4. `make uninstall-setup` - firmware and udev rules removed
5. `make uninstall` - kernel modules removed
6. No deprecation warnings when using Makefile targets