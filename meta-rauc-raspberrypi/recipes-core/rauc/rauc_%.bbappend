FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://rauc-grow-data-partition.service \
    file://info-provider.sh \
    file://pre-install.sh \
    file://post-install.sh \
    file://backend.sh \
    file://install_update \
    file://rauc-init.sh \
    file://boot-slot-seed.sh \
    file://boot-slot-seed.service \
    file://boot-mark-good.service \
"

inherit systemd

# ---------------------------
# Packages
# ---------------------------
# Gebruik consequent het subpacketschema op basis van ${PN}
PACKAGES += "${PN}-grow-data-part"

# Waar zitten de files?
FILES:${PN} += " \
    ${sbindir}/boot-slot-seed.sh \
    ${systemd_system_unitdir}/boot-slot-seed.service \
    ${systemd_system_unitdir}/boot-mark-good.service \
    ${libdir}/rauc/* \
"

FILES:${PN}-grow-data-part += " \
    ${systemd_system_unitdir}/rauc-grow-data-partition.service \
"

# ---------------------------
# Systemd integratie
# ---------------------------
SYSTEMD_PACKAGES = "${PN} ${PN}-grow-data-part"

# Services per package (meerdere kan)
SYSTEMD_SERVICE:${PN} = "boot-slot-seed.service boot-mark-good.service"
SYSTEMD_SERVICE:${PN}-grow-data-part = "rauc-grow-data-partition.service"

# Auto-enable per package (optioneel, default is 'enable' als je dat wil)
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
SYSTEMD_AUTO_ENABLE:${PN}-grow-data-part = "enable"

# ---------------------------
# Runtime deps
# ---------------------------
RDEPENDS:${PN} += "bash util-linux-blkid e2fsprogs-mke2fs e2fsprogs coreutils tar"
RDEPENDS:${PN}-grow-data-part += "parted"
RDEPENDS:${PN} += "u-boot-fw-utils u-boot-env"

# ---------------------------
# Install
# ---------------------------
do_install:append() {
    install -d ${D}${libdir}/rauc ${D}${sbindir} ${D}${systemd_system_unitdir}

    install -m 0755 ${WORKDIR}/info-provider.sh ${D}${libdir}/rauc/
    install -m 0755 ${WORKDIR}/pre-install.sh ${D}${libdir}/rauc/
    install -m 0755 ${WORKDIR}/post-install.sh ${D}${libdir}/rauc/
    install -m 0755 ${WORKDIR}/backend.sh ${D}${libdir}/rauc/
    install -m 0755 ${WORKDIR}/install_update ${D}${libdir}/rauc/
    install -m 0755 ${WORKDIR}/rauc-init.sh ${D}${libdir}/rauc/

    install -m 0755 ${WORKDIR}/boot-slot-seed.sh ${D}${sbindir}/
    install -m 0644 ${WORKDIR}/boot-slot-seed.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/boot-mark-good.service ${D}${systemd_system_unitdir}/

    install -m 0644 ${WORKDIR}/rauc-grow-data-partition.service ${D}${systemd_system_unitdir}/
}
