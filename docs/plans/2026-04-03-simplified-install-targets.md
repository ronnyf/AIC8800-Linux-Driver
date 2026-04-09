# Simplified Makefile Install/Uninstall Targets

> **For agentic workers:** Use superpowers:subagent-driven-development (recommended) to implement this plan task-by-task.

**Goal:** Remove bash helper scripts entirely; implement all install/uninstall functionality as Makefile targets only

**Architecture:**
- Replace `drivers/aic8800/Makefile` install/uninstall targets with modular targets
- Add: `install_firmware`, `install_rules`, `install_modules`, `install` (composite)
- Add: `uninstall_firmware`, `uninstall_rules`, `uninstall_modules`, `uninstall` (composite)
- Remove: `install_setup.sh`, `uninstall_setup.sh`, and helper scripts
- Remove: Legacy bash scripts (legacy scripts marked as deprecated first)

**Tech Stack:** Linux kernel 6.19, clang 22.1.2, X86_64

---

## Files to modify

1. `drivers/aic8800/Makefile` - Replace install/uninstall with modular targets
2. `install_setup.sh` - Mark deprecated, remove file
3. `uninstall_setup.sh` - Mark deprecated, remove file

---

### Task 1: Update Makefile with modular targets

**Files:**
- Modify: `drivers/aic8800/Makefile:62-76`

**Steps:**
- [ ] **Step 1: Replace install/uninstall targets**

At lines 62-76, replace:
```makefile
MAKEFLAGS +=-j$(shell nproc)

all: modules
modules:
	make -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

install:
	mkdir -p $(MODDESTDIR)
	install -p -m 644 aic_load_fw/aic_load_fw.ko  $(MODDESTDIR)/
	install -p -m 644 aic8800_fdrv/aic8800_fdrv.ko  $(MODDESTDIR)/
	/sbin/depmod -a ${KVER}

uninstall:
	rm -rfv $(MODDESTDIR)/aic_load_fw.ko
	rm -rfv $(MODDESTDIR)/aic8800_fdrv.ko
	/sbin/depmod -a ${KVER}

clean:
	cd aic_load_fw/;make clean;cd ..
	cd aic8800_fdrv/;make clean;cd ..
	rm -rf modules.order Module.symvers .modules.order.cmd ..module-common.o.cmd .Module.symvers.cmd .module-common.o .tmp_versions/
```

To:
```makefile
MAKEFLAGS +=-j$(shell nproc)

# Install/uninstall paths
FIRMWARE_PATH ?= ./fw/aic8800D80
FIRMWARE_DEST ?= /lib/firmware
UDEV_RULES_SRC ?= ./tools/aic.rules
UDEV_RULES_DEST ?= /etc/udev/rules.d

all: modules
modules:
	make -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

# Modular install targets
install_firmware:
	@test -d $(FIRMWARE_PATH) || { echo "ERROR: Firmware directory $(FIRMWARE_PATH) not found" >&2; exit 1; }
	@echo "Installing firmware to $(FIRMWARE_DEST)..."
	sudo cp -rf $(FIRMWARE_PATH)/* $(FIRMWARE_DEST)/

install_rules:
	@test -f $(UDEV_RULES_SRC) || { echo "ERROR: Udev rules file $(UDEV_RULES_SRC) not found" >&2; exit 1; }
	@echo "Installing udev rules to $(UDEV_RULES_DEST)..."
	sudo cp $(UDEV_RULES_SRC) $(UDEV_RULES_DEST)/
	sudo udevadm trigger
	sudo udevadm control --reload

install_modules:
	mkdir -p $(MODDESTDIR)
	install -p -m 644 aic_load_fw/aic_load_fw.ko  $(MODDESTDIR)/
	install -p -m 644 aic8800_fdrv/aic8800_fdrv.ko  $(MODDESTDIR)/
	/sbin/depmod -a ${KVER}

install: install_firmware install_rules install_modules
	@echo "All components installed successfully!"

# Modular uninstall targets
uninstall_firmware:
	@test -d $(FIRMWARE_DEST)/aic8800D80 || { echo "WARNING: Firmware $(FIRMWARE_DEST)/aic8800D80 not found, skipping" >&2; } || true
	@echo "Uninstalling firmware from $(FIRMWARE_DEST)..."
	sudo rm -rf $(FIRMWARE_DEST)/aic8800D80

uninstall_rules:
	@test -f $(UDEV_RULES_DEST)/aic.rules || { echo "WARNING: Udev rules $(UDEV_RULES_DEST)/aic.rules not found, skipping" >&2; } || true
	@echo "Uninstalling udev rules from $(UDEV_RULES_DEST)..."
	sudo rm $(UDEV_RULES_DEST)/aic.rules

uninstall_modules:
	rm -rfv $(MODDESTDIR)/aic_load_fw.ko
	rm -rfv $(MODDESTDIR)/aic8800_fdrv.ko
	/sbin/depmod -a ${KVER}

uninstall: uninstall_firmware uninstall_rules uninstall_modules
	@echo "All components uninstalled successfully!"

clean:
	cd aic_load_fw/;make clean;cd ..
	cd aic8800_fdrv/;make clean;cd ..
	rm -rf modules.order Module.symvers .modules.order.cmd .module-common.o.cmd .Module.symvers.cmd .module-common.o .tmp_versions/
```

- [ ] **Step 2: Commit Makefile update**

```bash
git add drivers/aic8800/Makefile
git commit -m "makefile: refactor install/uninstall into modular targets"
```

---

### Task 2: Mark legacy scripts as deprecated

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

echo "WARNING: install_setup.sh is DEPRECATED and will be removed."
echo "Use 'make install' (or modular targets: install_firmware, install_rules, install_modules)"
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
echo "WARNING: uninstall_setup.sh is DEPRECATED and will be removed."
echo "Use 'make uninstall' (or modular targets: uninstall_firmware, uninstall_rules, uninstall_modules)"
echo ""
echo "Clean aic8800 wifi driver setup files (legacy)!"
echo "Authentication requested [root] for clean:"
```

- [ ] **Step 3: Commit deprecation messages**

```bash
git add install_setup.sh uninstall_setup.sh
git commit -m "install_setup: mark as deprecated, use Makefile targets instead"
```

---

### Task 3: Remove legacy scripts

**Files:**
- Delete: `install_setup.sh`
- Delete: `uninstall_setup.sh`

**Steps:**
- [ ] **Step 1: Delete legacy scripts**

```bash
rm install_setup.sh uninstall_setup.sh
```

- [ ] **Step 2: Remove helper scripts (if any exist)**

```bash
rm drivers/aic8800/install-setup-script.sh drivers/aic8800/uninstall-setup-script.sh 2>/dev/null || true
```

- [ ] **Step 3: Commit script removal**

```bash
git add install_setup.sh uninstall_setup.sh
git commit -m "install_setup: remove legacy bash scripts (replaced by Makefile targets)"
```

- [ ] **Step 4: Update AGENTS.md**

At line 6 in `AGENTS.md`, change:
```makefile
**Install/Clean/Uninstall**: `make -C drivers/aic8800 {install,install-setup,clean,uninstall,uninstall-setup}`
```

To:
```makefile
**Install/Clean/Uninstall**: `make -C drivers/aic8800 {install,install_firmware,install_rules,install_modules,clean,uninstall,uninstall_firmware,uninstall_rules,uninstall_modules}`
```

- [ ] **Step 5: Commit AGENTS update**

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md to reflect new modular Makefile targets"
```

---

### Task 4: Build and test verification

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

- [ ] **Step 3: Test modular install targets**

```bash
make -C drivers/aic8800 install_firmware
make -C drivers/aic8800 install_rules
make -C drivers/aic8800 install_modules
```

Expected: All install targets complete successfully

- [ ] **Step 4: Test composite install**

```bash
make -C drivers/aic8800 install
```

Expected: All components installed in correct order

- [ ] **Step 5: Test modular uninstall targets**

```bash
make -C drivers/aic8800 uninstall_firmware
make -C drivers/aic8800 uninstall_rules
make -C drivers/aic8800 uninstall_modules
```

Expected: All uninstall targets complete successfully

- [ ] **Step 6: Test composite uninstall**

```bash
make -C drivers/aic8800 uninstall
```

Expected: All components uninstalled in correct order

- [ ] **Step 7: Test idempotency**

```bash
make -C drivers/aic8800 uninstall_firmware
```

Expected: No errors even if firmware already removed

- [ ] **Step 8: Final commit**

```bash
git add .
git commit -m "test: verify all Makefile install/uninstall targets work correctly"
```

---

## Verification

After all tasks complete:

1. Run build: `make LLVM=1 -C drivers/aic8800` - should pass with 0 errors
2. `make install_firmware` - firmware copied successfully
3. `make install_rules` - udev rules copied and udev reloaded
4. `make install_modules` - kernel modules installed with depmod
5. `make install` - all components installed in order
6. `make uninstall_firmware` - firmware removed (idempotent)
7. `make uninstall_rules` - udev rules removed (idempotent)
8. `make uninstall_modules` - kernel modules uninstalled
9. `make uninstall` - all components uninstalled in order
10. No bash helper scripts remain in repo