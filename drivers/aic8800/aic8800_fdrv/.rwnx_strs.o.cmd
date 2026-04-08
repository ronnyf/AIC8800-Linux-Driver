savedcmd_aic8800_fdrv/rwnx_strs.o := clang -Wp,-MMD,aic8800_fdrv/.rwnx_strs.o.d -nostdinc -I/usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include -I/usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include/generated -I/usr/lib/modules/6.19.10-1-cachyos/build/include -I/usr/lib/modules/6.19.10-1-cachyos/build/include -I/usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include/uapi -I/usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include/generated/uapi -I/usr/lib/modules/6.19.10-1-cachyos/build/include/uapi -I/usr/lib/modules/6.19.10-1-cachyos/build/include/generated/uapi -include /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/compiler-version.h -include /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/kconfig.h -include /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/compiler_types.h -D__KERNEL__ --target=x86_64-linux-gnu -fintegrated-as -Werror=ignored-optimization-argument -Werror=option-ignored -std=gnu11 -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -mno-sse -mno-mmx -mno-sse2 -mno-3dnow -mno-avx -mno-sse4a -fcf-protection=branch -fno-jump-tables -m64 -falign-loops=1 -mno-80387 -mno-fp-ret-in-387 -mstack-alignment=8 -mskip-rax-setup -march=x86-64-v4 -mno-red-zone -mcmodel=kernel -mstack-protector-guard-reg=gs -mstack-protector-guard-symbol=__ref_stack_chk_guard -Wno-sign-compare -fno-asynchronous-unwind-tables -mretpoline-external-thunk -mindirect-branch-cs-prefix -mfunction-return=thunk-extern -mharden-sls=all -fpatchable-function-entry=16,16 -fno-delete-null-pointer-checks -O3 -fstack-protector-strong -ftrivial-auto-var-init=zero -fno-stack-clash-protection -pg -mfentry -DCC_USING_NOP_MCOUNT -DCC_USING_FENTRY -fno-lto -flto=thin -fsplit-lto-unit -fvisibility=hidden -falign-functions=16 -fstrict-flex-arrays=3 -fms-extensions -fno-strict-overflow -fno-stack-check -fno-builtin-wcslen -Wall -Wextra -Wundef -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Wno-format-security -Wno-trigraphs -Wno-frame-address -Wno-address-of-packed-member -Wmissing-declarations -Wmissing-prototypes -Wframe-larger-than=2048 -Wno-gnu -Wno-microsoft-anon-tag -Wno-format-overflow-non-kprintf -Wno-format-truncation-non-kprintf -Wno-default-const-init-unsafe -Wno-pointer-sign -Wcast-function-type -Wno-unterminated-string-initialization -Wimplicit-fallthrough -Werror=date-time -Wenum-conversion -Wunused -Wno-unused-but-set-variable -Wno-unused-const-variable -Wno-format-overflow -Wno-override-init -Wno-pointer-to-enum-cast -Wno-tautological-constant-out-of-range-compare -Wno-unaligned-access -Wno-enum-compare-conditional -Wno-missing-field-initializers -Wno-type-limits -Wno-shift-negative-value -Wno-enum-enum-conversion -Wno-sign-compare -Wno-unused-parameter -g -gdwarf-5 -DNX_VIRT_DEV_MAX=4 -DNX_REMOTE_STA_MAX_FOR_OLD_IC=8 -DNX_REMOTE_STA_MAX=32 -DNX_MU_GROUP_MAX=62 -DNX_TXDESC_CNT=64 -DNX_TX_MAX_RATES=4 -DNX_CHAN_CTXT_CNT=3 -DCONFIG_START_FROM_BOOTROM -DCONFIG_VRF_DCDC_MODE -DCONFIG_ROM_PATCH_EN -DCONFIG_COEX -DCONFIG_RWNX_FULLMAC -I./aic8800_fdrv/. -DCONFIG_RWNX_RADAR -DCONFIG_RFTEST -DCONFIG_MCC -DAICWF_USB_SUPPORT -DCONFIG_USER_MAX=1 -DNX_TXQ_CNT=5 -DAICWF_RX_REORDER -DAICWF_ARP_OFFLOAD -DUSE_5G -DCONFIG_USB_BT -DCONFIG_ALIGN_8BYTES -DCONFIG_TXRX_THREAD_PRIO -DCONFIG_USB_ALIGN_DATA -DCONFIG_MAC_RANDOM_IF_NO_MAC_IN_EFUSE -DDEFAULT_COUNTRY_CODE=""\"00""\" -DCONFIG_RX_NETIF_RECV_SKB -DCONFIG_USB_MSG_OUT_EP -DCONFIG_USB_MSG_IN_EP -DCONFIG_USE_USB_ZERO_PACKET -DCONFIG_PREALLOC_RX_SKB -DCONFIG_PREALLOC_TXQ -DCONFIG_USE_WIRELESS_EXT -DCONFIG_DPD -DCONFIG_FORCE_DPD_CALIB -DCONFIG_DPD -DCONFIG_FILTER_TCP_ACK  -fdebug-info-for-profiling -mllvm -enable-fs-discriminator=true -mllvm -improved-fs-discriminator=true  -DMODULE  -DKBUILD_BASENAME='"rwnx_strs"' -DKBUILD_MODNAME='"aic8800_fdrv"' -D__KBUILD_MODNAME=aic8800_fdrv -c -o aic8800_fdrv/rwnx_strs.o aic8800_fdrv/rwnx_strs.c  

source_aic8800_fdrv/rwnx_strs.o := aic8800_fdrv/rwnx_strs.c

deps_aic8800_fdrv/rwnx_strs.o := \
    $(wildcard include/config/RWNX_FULLMAC) \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/compiler-version.h \
    $(wildcard include/config/CC_VERSION_TEXT) \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/kconfig.h \
    $(wildcard include/config/CPU_BIG_ENDIAN) \
    $(wildcard include/config/BOOGER) \
    $(wildcard include/config/FOO) \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/compiler_types.h \
    $(wildcard include/config/DEBUG_INFO_BTF) \
    $(wildcard include/config/PAHOLE_HAS_BTF_TAG) \
    $(wildcard include/config/FUNCTION_ALIGNMENT) \
    $(wildcard include/config/CC_HAS_SANE_FUNCTION_ALIGNMENT) \
    $(wildcard include/config/X86_64) \
    $(wildcard include/config/ARM64) \
    $(wildcard include/config/LD_DEAD_CODE_DATA_ELIMINATION) \
    $(wildcard include/config/LTO_CLANG) \
    $(wildcard include/config/HAVE_ARCH_COMPILER_H) \
    $(wildcard include/config/KCSAN) \
    $(wildcard include/config/CC_HAS_ASSUME) \
    $(wildcard include/config/CC_HAS_COUNTED_BY) \
    $(wildcard include/config/CC_HAS_MULTIDIMENSIONAL_NONSTRING) \
    $(wildcard include/config/UBSAN_INTEGER_WRAP) \
    $(wildcard include/config/CFI) \
    $(wildcard include/config/ARCH_USES_CFI_GENERIC_LLVM_PASS) \
    $(wildcard include/config/CC_HAS_ASM_INLINE) \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/compiler_attributes.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/compiler-clang.h \
    $(wildcard include/config/ARCH_USE_BUILTIN_BSWAP) \
    $(wildcard include/config/CC_HAS_TYPEOF_UNQUAL) \
  aic8800_fdrv/lmac_msg.h \
    $(wildcard include/config/RWNX_FHOST) \
    $(wildcard include/config/USB_BT) \
  aic8800_fdrv/lmac_mac.h \
    $(wildcard include/config/HE_FOR_OLD_KERNEL) \
    $(wildcard include/config/VHT_FOR_OLD_KERNEL) \
  aic8800_fdrv/lmac_types.h \
    $(wildcard include/config/RWNX_TL4) \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/generated/uapi/linux/version.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/types.h \
    $(wildcard include/config/HAVE_UID16) \
    $(wildcard include/config/UID16) \
    $(wildcard include/config/ARCH_DMA_ADDR_T_64BIT) \
    $(wildcard include/config/PHYS_ADDR_T_64BIT) \
    $(wildcard include/config/64BIT) \
    $(wildcard include/config/ARCH_32BIT_USTAT_F_TINODE) \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/linux/types.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include/generated/uapi/asm/types.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/asm-generic/types.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/asm-generic/int-ll64.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/asm-generic/int-ll64.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include/uapi/asm/bitsperlong.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/asm-generic/bitsperlong.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/asm-generic/bitsperlong.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/linux/posix_types.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/stddef.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/linux/stddef.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include/asm/posix_types.h \
    $(wildcard include/config/X86_32) \
  /usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include/uapi/asm/posix_types_64.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/asm-generic/posix_types.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/bits.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/vdso/bits.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/vdso/const.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/linux/const.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/linux/bits.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/build_bug.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/compiler.h \
    $(wildcard include/config/TRACE_BRANCH_PROFILING) \
    $(wildcard include/config/PROFILE_ALL_BRANCHES) \
    $(wildcard include/config/OBJTOOL) \
  /usr/lib/modules/6.19.10-1-cachyos/build/arch/x86/include/generated/asm/rwonce.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/asm-generic/rwonce.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/kasan-checks.h \
    $(wildcard include/config/KASAN_GENERIC) \
    $(wildcard include/config/KASAN_SW_TAGS) \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/kcsan-checks.h \
    $(wildcard include/config/KCSAN_WEAK_MEMORY) \
    $(wildcard include/config/KCSAN_IGNORE_ATOMICS) \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/overflow.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/limits.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/uapi/linux/limits.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/vdso/limits.h \
  /usr/lib/modules/6.19.10-1-cachyos/build/include/linux/const.h \

aic8800_fdrv/rwnx_strs.o: $(deps_aic8800_fdrv/rwnx_strs.o)

$(deps_aic8800_fdrv/rwnx_strs.o):
