CONFIG_AIC_LOADFW_SUPPORT := m
CONFIG_AIC8800_WLAN_SUPPORT := m

obj-$(CONFIG_AIC_LOADFW_SUPPORT)    += aic_load_fw/
obj-$(CONFIG_AIC8800_WLAN_SUPPORT) += aic8800_fdrv/

########## config option ##########
export CONFIG_USE_FW_REQUEST = n
export CONFIG_PREALLOC_RX_SKB = y
export CONFIG_PREALLOC_TXQ = y
###################################

KDIR  = /lib/modules/$(shell uname -r)/build
PWD   = $(shell pwd)
KVER = $(shell uname -r)
MODDESTDIR = /lib/modules/$(KVER)/kernel/drivers/net/wireless/aic8800
SUBARCH = $(shell uname -m | sed -e s/i.86/i386/ -e s/armv.l/arm/ -e s/aarch64/arm64/ -e s/loongarch64/loongarch/ -e s/loong64/loongarch/)
ARCH ?= $(SUBARCH)
CROSS_COMPILE ?=

# Match the compiler/toolchain used to build the running kernel
MAKEOVERRIDES := $(filter-out LLVM=% LLVM_IAS=%,$(MAKEOVERRIDES))
_KERN_CLANG := $(shell grep -q CONFIG_CC_IS_CLANG $(KDIR)/.config 2>/dev/null && echo 1)
_KERN_LLD := $(shell grep -q CONFIG_LLD_VERSION $(KDIR)/.config 2>/dev/null && echo 1)
_KERN_FLAGS :=
ifeq ($(_KERN_CLANG),1)
  _KERN_FLAGS += LLVM=1 LLVM_IAS=1
endif


MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
FIRMWARE_PATH ?= $(MAKEFILE_DIR)../../fw/aic8800D80
FIRMWARE_DEST ?= /lib/firmware/aic8800D80
UDEV_RULES_SRC ?= $(MAKEFILE_DIR)../../tools/aic.rules
UDEV_RULES_DEST ?= /etc/udev/rules.d

all: modules
modules:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(_KERN_FLAGS) modules

install_firmware:
	@test -d $(FIRMWARE_PATH) || { echo "ERROR: Firmware directory $(FIRMWARE_PATH) not found" >&2; exit 1; }
	@echo "Installing firmware to $(FIRMWARE_DEST)..."
	@if [ ! -d "$(FIRMWARE_DEST)" ]; then \
		echo "Creating $(FIRMWARE_DEST)"; \
		sudo mkdir -p $(FIRMWARE_DEST); \
	fi
	sudo cp -rf $(FIRMWARE_PATH)/* $(FIRMWARE_DEST)

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

uninstall_firmware:
	@test -d $(FIRMWARE_DEST) || { echo "WARNING: Firmware $(FIRMWARE_DEST) not found, skipping" >&2; } || true
	@echo "Uninstalling firmware from $(FIRMWARE_DEST)..."
	sudo rm -rf $(FIRMWARE_DEST)

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
	rm -rf modules.order Module.symvers .modules.order.cmd ..module-common.o.cmd .Module.symvers.cmd .module-common.o .tmp_versions/

.PHONY: modules install_modules uninstall_modules
