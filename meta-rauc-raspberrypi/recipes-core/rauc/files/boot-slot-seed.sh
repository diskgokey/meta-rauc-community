#!/bin/sh
# BusyBox/ash compatible
# Seed /boot into boot_a / boot_b if they are empty or incomplete (e.g. overlays/ missing).
# One-time by default (stamp), override with --force.

set -eu

STAMP="/var/lib/boot-slot-seed.done"
SRC="/boot"

log() { echo "[boot-slot-seed] $*"; logger -t boot-slot-seed "$*"; }

# return mountpoint if device already mounted; else empty
existing_mountpoint() {
  dev="$1"
  awk -v d="$dev" '$1==d {print $2; exit}' /proc/mounts
}

# temporary mount RW, run a function with $1=mountpoint, then cleanup if we mounted it
with_temp_mount_rw() {
  dev="$1"; shift
  mp="$(existing_mountpoint "$dev" || true)"
  created=0
  if [ -z "$mp" ]; then
    TMPDIR="${TMPDIR:-/run}"
    [ -d "$TMPDIR" ] || TMPDIR=/tmp
    mp="$(mktemp -d "$TMPDIR/tmpmnt.XXXXXX")"
    mount -o rw "$dev" "$mp"
    created=1
  else
    mount -o remount,rw "$mp" 2>/dev/null || true
  fi

  func="$1"; shift
  "$func" "$mp" "$@"
  rc=$?

  if [ "$created" -eq 1 ]; then
    sync || true
    umount "$mp" || rc=$?
    rmdir "$mp" || true
  fi
  return $rc
}

# candidate device nodes per slot
resolve_dev() {
  slot="$1"
  for d in "/dev/disk/by-partlabel/$slot" \
           "/dev/mmcblk0p2" "/dev/mmcblk0p3"; do
    case "$slot:$d" in
      boot_a:/dev/mmcblk0p3) continue ;;
      boot_b:/dev/mmcblk0p2) continue ;;
    esac
    [ -e "$d" ] && { echo "$d"; return 0; }
  done
  return 1
}

# ext4 if missing
ensure_fs() {
  dev="$1"; label="$2"
  if ! blkid -o value -s TYPE "$dev" >/dev/null 2>&1; then
    log "$label: creating ext4 on $dev"
    mkfs.ext4 -F -L "$label" "$dev"
    command -v udevadm >/dev/null 2>&1 && udevadm settle || true
  fi
}

# true if dir has no entries except maybe lost+found
is_effectively_empty() {
  dir="$1"
  found=""
  for f in "$dir"/* "$dir"/.[!.]* "$dir"/.??*; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    [ "$base" = "lost+found" ] && continue
    found="yes"
    break
  done
  [ -z "$found" ]  # empty => return 0
}

# decide if a slot needs (re)seeding (empty OR key files/dirs missing)
slot_needs_seed() {
  mp="$1"
  if is_effectively_empty "$mp"; then
    return 0
  fi
  # minimal RPi boot contents we expect
  [ -f "$mp/config.txt" ] || return 0
  if [ -f "$mp/start.elf" ] || [ -f "$mp/start4.elf" ]; then :; else return 0; fi
  [ -d "$mp/overlays" ] || return 0
  return 1
}

copy_boot_into() {
  dst="$1"
  if command -v rsync >/dev/null 2>&1; then
    rsync -aHAX --delete "$SRC"/ "$dst"/
  elif cp --help 2>/dev/null | grep -q '\-a'; then
    cp -a "$SRC"/. "$dst"/
  else
    (cd "$SRC" && tar -cf - .) | (cd "$dst" && tar -xf -)
  fi
}

seed_slot_mp() {  # called via with_temp_mount_rw
  mp="$1"
  if slot_needs_seed "$mp"; then
    log "$SLOT_NAME needs seeding; copying from $SRC"
    copy_boot_into "$mp"
    date > "$mp/.boot-slot-seeded" || true
  else
    log "$SLOT_NAME already looks complete; skipping"
  fi
}

seed_one() {
  SLOT_NAME="$1"  # exported to seed_slot_mp via env
  dev="$(resolve_dev "$SLOT_NAME")" || { log "skip $SLOT_NAME: no device"; return 0; }
  ensure_fs "$dev" "$SLOT_NAME"
  with_temp_mount_rw "$dev" seed_slot_mp
}

main() {
  FORCE=0
  if [ "${1:-}" = "--force" ]; then
    FORCE=1
    shift
  fi

  if [ $FORCE -eq 0 ] && [ -f "$STAMP" ]; then
    log "already done ($STAMP)"
    exit 0
  fi

  # make sure /boot is mounted (we only read from it)
  if ! awk '$2=="/boot"{found=1} END{exit !found}' /proc/mounts; then
    log "ERROR: /boot not mounted"
    exit 1
  fi

  mkdir -p "$(dirname "$STAMP")"

  seed_one boot_a
  seed_one boot_b

  [ $FORCE -eq 1 ] || touch "$STAMP"
  log "done; stamp at $STAMP (force=$FORCE)"
}

main "$@"
