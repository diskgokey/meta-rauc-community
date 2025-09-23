FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append := " \
			file://futech-cert.pem \
			file://rauc-init.service \
			file://system.conf \
			"

# geef alleen de bestandsnaam door (geen pad!)
RAUC_KEYRING_FILE = "futech-cert.pem"

do_install:prepend() {
	sed -i "s/HWID/futechr1/g" ${WORKDIR}/system.conf
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "rauc-init.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/rauc-init.service ${D}${systemd_unitdir}/system/
	install -d ${D}${sysconfdir}/rauc
    install -m 0755 ${WORKDIR}/futech-cert.pem ${D}${sysconfdir}/rauc
	install -m 0755 ${WORKDIR}/system.conf ${D}${sysconfdir}/rauc
}

FILES:${PN} += "${systemd_unitdir}/system/rauc-init.service"
RDEPENDS:${PN} += "rauc"