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


MODULE_INFO(depends, "cfg80211,aic_load_fw");

MODULE_ALIAS("usb:vA69Cp8801d*dc*dsc*dp*icFFiscFFipFFin*");
MODULE_ALIAS("usb:vA69Cp8D81d*dc*dsc*dp*icFFiscFFipFFin*");
MODULE_ALIAS("usb:vA69Cp8D41d*dc*dsc*dp*icFFiscFFipFFin*");
MODULE_ALIAS("usb:vA69Cp88DCd*dc*dsc*dp*icFFiscFFipFFin*");
MODULE_ALIAS("usb:vA69Cp88DDd*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D91d*dc*dsc*dp*icFFiscFFipFFin*");
MODULE_ALIAS("usb:v368Bp8D99d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:vA69Cp8D83d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v2357p014Ed*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v2357p014Bd*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v2357p014Fd*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v2604p001Fd*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D83d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D84d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D85d*dc*dsc*dp*ic*isc*ip*in*");
MODULE_ALIAS("usb:v368Bp8D88d*dc*dsc*dp*ic*isc*ip*in*");

MODULE_INFO(srcversion, "8E6D39E945EBB3316A9F4AB");
