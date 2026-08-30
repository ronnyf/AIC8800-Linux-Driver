# Cài đặt driver WiFi AIC8800

Tài liệu này hướng dẫn cài driver AIC8800 (D80/DC/DW) trên Linux. Không dùng
màu trong output `make` — nếu terminal tự tô màu cảnh báo/lỗi, thêm cờ tắt màu
như ghi ở cuối mục Build.

## 1. Cách khuyến nghị: pacman repo (Arch/CachyOS)

Thêm vào `/etc/pacman.conf`:

```ini
[aic8800]
SigLevel = Optional TrustAll
Server = https://ronnyf.github.io/AIC8800-Linux-Driver/x86_64
```

Cài:

```bash
sudo pacman -Sy aic8800/aic8800-fdrv-dkms
sudo pacman -S linux-headers          # hoặc linux-cachyos-headers, linux-lts-headers, linux-zen-headers
```

DKMS tự rebuild module mỗi lần kernel cập nhật. Gói không ký PGP (vì vậy cần
`SigLevel = Optional TrustAll`) — nếu không chấp nhận, build từ `PKGBUILD`
đính kèm trong [release](https://github.com/ronnyf/AIC8800-Linux-Driver/releases).

## 2. Build từ source

Yêu cầu: `linux-headers` khớp kernel đang chạy, `make`, và `clang` nếu kernel
được build bằng clang (CachyOS/Arch thường vậy — GCC sẽ lỗi cờ không nhận diện
được như `-mstack-alignment`).

```bash
git clone https://github.com/ronnyf/AIC8800-Linux-Driver.git
cd AIC8800-Linux-Driver

make -C drivers/aic8800          # tự nhận diện clang/gcc theo kernel
# hoặc ép compiler:
make LLVM=1 -C drivers/aic8800   # clang
make LLVM=0 -C drivers/aic8800   # gcc (chỉ chạy nếu kernel build bằng gcc)

sudo make -C drivers/aic8800 install
```

`install` chạy 3 target: `install_firmware`, `install_rules`, `install_modules`.
Có thể chạy riêng từng cái nếu chỉ cần cập nhật 1 phần.

Gỡ: `sudo make -C drivers/aic8800 uninstall` (hoặc `uninstall_firmware` /
`uninstall_rules` / `uninstall_modules` riêng lẻ).

Dọn build artifact: `make -C drivers/aic8800 clean`.

**Tắt màu output**: `make`/kbuild tự tắt màu khi stdout không phải terminal
(ví dụ redirect ra file hay pipe qua `tee`). Nếu vẫn thấy mã màu ANSI, build
lại với:

```bash
NO_COLOR=1 make -C drivers/aic8800                       # honor NO_COLOR chung
make LLVM=1 KCFLAGS=-fno-color-diagnostics -C drivers/aic8800   # clang
make LLVM=0 KCFLAGS=-fdiagnostics-color=never -C drivers/aic8800 # gcc
```

## 3. DKMS thủ công (không qua pacman)

```bash
sudo dkms add ./
sudo dkms build aic8800-fdrv-dkms/6.4.3.0
sudo dkms install aic8800-fdrv-dkms/6.4.3.0
```

## 4. Load module và kiểm tra

```bash
sudo modprobe aic_load_fw
sudo modprobe aic8800_fdrv

lsmod | grep aic
iwconfig
dmesg | tail -20
```

## 5. Kernel hỗ trợ

Kernel 6.0 → 7.2. Kernel 7.3 **chưa** hỗ trợ (upstream đổi behaviour của
`cookie` trong cfg80211, `.remain_on_channel`/`.mgmt_tx`, và bỏ `.probe_client`
khỏi `struct cfg80211_ops`).
