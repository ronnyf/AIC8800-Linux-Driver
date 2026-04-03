CONFIG_AIC_LOADFW_SUPPORT := m
CONFIG_AIC8800_WLAN_SUPPORT := m

obj-$(CONFIG_AIC_LOADFW_SUPPORT)    += aic_load_fw/
obj-$(CONFIG_AIC8800_WLAN_SUPPORT) += aic8800_fdrv/

########## config option ##########
export CONFIG_USE_FW_REQUEST = n
export CONFIG_PREALLOC_RX_SKB = y
export CONFIG_PREALLOC_TXQ = y
###################################

########## platform support list ##########
export CONFIG_PLATFORM_ROCKCHIP = n
export CONFIG_PLATFORM_ALLWINNER = n
export CONFIG_PLATFORM_AMLOGIC = n
export CONFIG_PLATFORM_HI = n
export CONFIG_PLATFORM_UBUNTU = y

ifeq ($(CONFIG_PLATFORM_ROCKCHIP), y)
ARCH = arm64
KDIR = /home/yaya/E/Rockchip/3566/firefly/Android11.0/Firefly-RK356X_Android11.0_git_20210824/RK356X_Android11.0/kernel
CROSS_COMPILE = /home/yaya/E/Rockchip/3566/firefly/Android11.0/Firefly-RK356X_Android11.0_git_20210824/RK356X_Android11.0/prebuilts/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
ccflags-y += -DANDROID_PLATFORM
endif

ifeq ($(CONFIG_PLATFORM_ALLWINNER), y)
KDIR  = /home/yaya/E/Allwinner/R818/R818/AndroidQ/lichee/kernel/linux-4.9
ARCH = arm64
CROSS_COMPILE = /home/yaya/E/Allwinner/R818/R818/AndroidQ/lichee/out/gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
ccflags-y += -DANDROID_PLATFORM
endif

ifeq ($(CONFIG_PLATFORM_AMLOGIC), y)
ccflags-y += -DANDROID_PLATFORM
ARCH = arm
CROSS_COMPILE = /home/yaya/D/Workspace/CyberQuantum/JinHaoYue/amls905x3/SDK/20191101-0tt-asop/android9.0/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androidkernel-
KDIR = /home/yaya/D/Workspace/CyberQuantum/JinHaoYue/amls905x3/SDK/20191101-0tt-asop/android9.0/out/target/product/u202/obj/KERNEL_OBJ/
endif

ifeq ($(CONFIG_PLATFORM_HI), y)
ccflags-y += -DANDROID_PLATFORM
ARCH = arm
CROSS_COMPILE = /home/yaya/D/Workspace/CyberQuantum/JinHaoYue/amls905x3/SDK/20191101-0tt-asop/android9.0/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androidkernel-
KDIR = /home/yaya/D/Workspace/CyberQuantum/JinHaoYue/amls905x3/SDK/20191101-0tt-asop/android9.0/out/target/product/u202/obj/KERNEL_OBJ/
endif

ifeq ($(CONFIG_PLATFORM_UBUNTU), y)
KDIR  = /lib/modules/$(shell uname -r)/build
PWD   = $(shell pwd)
KVER = $(shell uname -r)
MODDESTDIR = /lib/modules/$(KVER)/kernel/drivers/net/wireless/aic8800
SUBARCH = $(shell uname -m | sed -e s/i.86/i386/ -e s/armv.l/arm/ -e s/aarch64/arm64/ -e s/loongarch64/loongarch/ -e s/loong64/loongarch/)
ARCH ?= $(SUBARCH)
CROSS_COMPILE ?=
endif

###########################################

MAKEFLAGS +=-j$(shell nproc)

MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
FIRMWARE_PATH ?= $(MAKEFILE_DIR)../../fw/aic8800D80
FIRMWARE_DEST ?= /lib/firmware
UDEV_RULES_SRC ?= $(MAKEFILE_DIR)../../tools/aic.rules
UDEV_RULES_DEST ?= /etc/udev/rules.d

all: modules
modules:
	make -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

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
	rm -rf modules.order Module.symvers .modules.order.cmd ..module-common.o.cmd .Module.symvers.cmd .module-common.o .tmp_versions/
