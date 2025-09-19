FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append := "  \
	file://rauc-grow-data-partition.service \
	file://info-provider.sh \
	file://preinst.sh \
	file://postinst.sh \
	file://backend.sh \
	file://install_update \
	file://rauc-init.sh \
"

# additional dependencies required to run RAUC on the target
RDEPENDS:${PN} += "u-boot-fw-utils u-boot-env"

inherit systemd

SYSTEMD_PACKAGES += "${PN}-grow-data-part"
SYSTEMD_SERVICE:${PN}-grow-data-part = "rauc-grow-data-partition.service"

PACKAGES += "rauc-grow-data-part"

RDEPENDS:${PN}-grow-data-part += "parted"
RDEPENDS:${PN} += "bash"


do_install:append() {
	install -d ${D}${systemd_unitdir}/system/
	install -m 0644 ${WORKDIR}/rauc-grow-data-partition.service ${D}${systemd_unitdir}/system/
	install -d ${D}${libdir}/rauc
	install -m 0755 ${WORKDIR}/info-provider.sh ${D}${libdir}/rauc
	install -m 0755 ${WORKDIR}/preinst.sh ${D}${libdir}/rauc
	install -m 0755 ${WORKDIR}/postinst.sh ${D}${libdir}/rauc
	install -m 0755 ${WORKDIR}/backend.sh ${D}${libdir}/rauc
	install -m 0755 ${WORKDIR}/install_update ${D}${libdir}/rauc
	install -m 0755 ${WORKDIR}/rauc-init.sh ${D}${libdir}/rauc
}
