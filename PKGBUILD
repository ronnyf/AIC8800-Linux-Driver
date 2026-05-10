# Maintainer: Ronny F. <ronnyf@icloud.com>

pkgname=aic8800-fdrv-dkms
pkgver=6.4.3.0
pkgrel=5
pkgdesc="AIC8800 (D80/DC/DW) USB WiFi driver - DKMS source package"
arch=('any')
url="https://github.com/ronnyf/AIC8800-Linux-Driver"
license=('GPL2')
depends=('dkms')
optdepends=('linux-headers: stock Arch kernel headers'
            'linux-cachyos-headers: CachyOS kernel headers'
            'linux-lts-headers: Arch LTS kernel headers'
            'linux-zen-headers: Arch Zen kernel headers'
            'clang: required when the running kernel was built with clang (CachyOS, etc.)')
provides=("${pkgname}")
conflicts=("${pkgname}")
backup=('etc/udev/rules.d/aic.rules')
install="${pkgname}.install"

_srcname="AIC8800-Linux-Driver-${pkgver}-${pkgrel}"
source=("${_srcname}.tar.gz::${url}/releases/download/v${pkgver}-${pkgrel}/${_srcname}.tar.gz")
sha256sums=('SKIP')

package() {
    cd "${srcdir}/${_srcname}"

    local dkms_dest="${pkgdir}/usr/src/${pkgname}-${pkgver}"

    install -dm 755 "${dkms_dest}"
    cp -r drivers/aic8800/aic_load_fw   "${dkms_dest}/"
    cp -r drivers/aic8800/aic8800_fdrv  "${dkms_dest}/"
    install -Dm 644 drivers/aic8800/Makefile "${dkms_dest}/Makefile"
    install -Dm 644 drivers/aic8800/Kconfig  "${dkms_dest}/Kconfig"

    install -Dm 644 dkms.conf "${dkms_dest}/dkms.conf"
    sed -i "s/^PACKAGE_VERSION=.*/PACKAGE_VERSION=\"${pkgver}\"/" "${dkms_dest}/dkms.conf"

    install -dm 755 "${pkgdir}/usr/lib/firmware/aic8800D80"
    cp -r fw/aic8800D80/* "${pkgdir}/usr/lib/firmware/aic8800D80/"

    install -Dm 644 tools/aic.rules "${pkgdir}/etc/udev/rules.d/aic.rules"

    install -Dm 644 LICENSE   "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
    install -Dm 644 README.md "${pkgdir}/usr/share/doc/${pkgname}/README.md"
}
