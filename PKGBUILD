# Maintainer: Ronny F. <ronnyf@icloud.com>

_pkgname=AIC8800-Linux-Driver
pkgname=aic8800-fdrv-dkms
pkgver=6.4.3.0
pkgrel=4
pkgdesc="AIC8800 Linux Driver (DKMS)"
arch=('x86_64' 'armv7h' 'aarch64')
url="https://github.com/ronnyf/AIC8800-Linux-Driver"
license=('GPL2')
depends=('linux-headers')
makedepends=()
optdepends=('dkms: auto-rebuild on kernel updates'
            'clang: for LLVM-based builds with fewer warnings')
provides=("${pkgname}")
conflicts=("${pkgname}")
backup=('etc/udev/rules.d/aic.rules')
install=aic8800.install

source=("$pkgname-$pkgver.tar.gz::https://github.com/ronnyf/AIC8800-Linux-Driver/archive/refs/heads/main.tar.gz"
        "dkms.conf")
md5sums=('SKIP'
         'SKIP')

prepare() {
    cd "$srcdir/$_pkgname-main"
    cp "$srcdir/dkms.conf" .
}

build() {
    echo "Build phase: DKMS will compile during installation"
}

package() {
    cd "$srcdir/$_pkgname-main"

    local dkms_dest="$pkgdir/usr/src/$pkgname-$pkgver"

    install -dm 755 "$dkms_dest"
    cp -r drivers/* "$dkms_dest/"
    install -Dm 644 dkms.conf "$dkms_dest/dkms.conf"

    # Firmware
    if [ -d "fw/aic8800D80" ]; then
        install -dm 755 "$pkgdir/usr/lib/firmware/aic8800D80"
        cp -r fw/aic8800D80/* "$pkgdir/usr/lib/firmware/aic8800D80/"
    fi

    # Udev rules
    if [ -f "tools/aic.rules" ]; then
        install -Dm 644 tools/aic.rules "$pkgdir/etc/udev/rules.d/aic.rules"
    fi

    # Documentation
    install -Dm 644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md" 2>/dev/null || true
}
