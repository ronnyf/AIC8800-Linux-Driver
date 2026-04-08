#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

KSYMTAB_FUNC(get_fw_path, "", "");
KSYMTAB_FUNC(get_testmode, "", "");
KSYMTAB_FUNC(set_testmode, "", "");
KSYMTAB_FUNC(get_hardware_info, "", "");
KSYMTAB_FUNC(get_adap_test, "", "");
KSYMTAB_FUNC(get_flash_bin_size, "", "");
KSYMTAB_FUNC(get_flash_bin_crc, "", "");
KSYMTAB_FUNC(get_userconfig_xtal_cap, "", "");
KSYMTAB_FUNC(get_userconfig_txpwr_idx, "", "");
KSYMTAB_FUNC(get_userconfig_txpwr_ofst, "", "");
KSYMTAB_FUNC(aicwf_rxbuff_size_get, "", "");
KSYMTAB_FUNC(aicwf_prealloc_rxbuff_alloc, "", "");
KSYMTAB_FUNC(aicwf_prealloc_rxbuff_free, "", "");
KSYMTAB_FUNC(aicwf_prealloc_txq_alloc, "", "");

MODULE_INFO(depends, "");

MODULE_ALIAS("usb:vA69Cp8800d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:vA69Cp8801d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:vA69Cp8D80d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:vA69Cp8D81d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:vA69Cp8D40d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:vA69Cp8D41d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D90d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D91d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D99d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D92d*dc*dsc*dp*ic*isc*ip*in*");

MODULE_INFO(srcversion, "F9C7083C299A25A1C99E21E");
