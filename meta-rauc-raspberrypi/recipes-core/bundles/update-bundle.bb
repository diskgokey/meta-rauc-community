DESCRIPTION = "RAUC bundle generator"

inherit bundle

RAUC_BUNDLE_COMPATIBLE = "${MACHINE}"
RAUC_BUNDLE_VERSION = "v${DATE}"
RAUC_BUNDLE_DESCRIPTION = "RAUC iLuCharge2 update"

RAUC_BUNDLE_FORMAT = "verity"

RAUC_BUNDLE_SLOTS = "rootfs"
RAUC_SLOT_rootfs = "yeti-yak-image"
RAUC_SLOT_rootfs[fstype] = "ext4"

RAUC_KEY_FILE ?= "${THISDIR}/files/futech-key.pem"
RAUC_CERT_FILE ?= "${THISDIR}/files/futech-cert.pem"
