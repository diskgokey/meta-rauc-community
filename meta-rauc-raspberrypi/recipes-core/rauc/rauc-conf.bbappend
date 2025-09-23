FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append := " \
    file://futech-cert.pem \
    file://rauc-init.service \
    file://system.conf \
"

# optional, if your system.conf references the HWID
do_install:prepend() {
    sed -i "s/HWID/futechr1/g" ${WORKDIR}/system.conf
}

inherit systemd

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "rauc-init.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -d ${D}${systemd_system_unitdir} ${D}${sysconfdir}/rauc
    install -m 0644 ${WORKDIR}/rauc-init.service ${D}${systemd_system_unitdir}/

    # config files (0644)
    install -m 0644 ${WORKDIR}/futech-cert.pem ${D}${sysconfdir}/rauc/
    install -m 0644 ${WORKDIR}/system.conf     ${D}${sysconfdir}/rauc/
}

FILES:${PN} += " \
    ${systemd_system_unitdir}/rauc-init.service \
    ${sysconfdir}/rauc/futech-cert.pem \
    ${sysconfdir}/rauc/system.conf \
"

RDEPENDS:${PN} += "rauc"
