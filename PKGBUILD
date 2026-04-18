# Maintainer: Your Name <youremail@domain.com>

_pkgname=AIC8800-Linux-Driver
pkgname=aic8800-fdrv-dkms
pkgver=6.4.3.0
pkgrel=2
pkgdesc="AIC8800 Linux Driver (DKMS)"
arch=('x86_64' 'armv7h' 'aarch64')
url="https://github.com/ronnyf/AIC8800-Linux-Driver"
license=('GPL2')
depends=('dkms' 'linux-headers')
makedepends=()
optdepends=()
provides=("${pkgname}")
conflicts=("${pkgname}")

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

post_build() {
    echo "Post-build: Copy firmware files if needed"
}

package() {
    cd "$srcdir/$_pkgname-main"
    
    install -dm 755 "$pkgdir/usr/src/$pkgname-$pkgver"
    cp -r drivers/* "$pkgdir/usr/src/$pkgname-$pkgver/"
    
    install -Dm 644 dkms.conf "$pkgdir/usr/src/$pkgname-$pkgver/dkms.conf"
    
    if [ -d "firmware" ]; then
        install -dm 755 "$pkgdir/lib/firmware"
        cp -r firmware/* "$pkgdir/lib/firmware/" 2>/dev/null || true
    fi
    
    install -Dm 644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md" 2>/dev/null || true
}
