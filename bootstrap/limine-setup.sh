#!/usr/bin/env bash
# Install the limine UEFI bootloader onto the ESP and generate limine.conf with
# the correct LUKS + btrfs-subvol kernel cmdline. Run from the Arch ISO after
# pacstrap (so the kernels and /usr/share/limine exist under $TARGET) and after
# btrfs-layout.sh (which mounts the ESP at $TARGET/boot). See docs/arch-install.md.
#
# Assumes Secure Boot is OFF (the EFI binary is not signed here). Microcode is
# embedded in the initramfs by the `microcode` mkinitcpio hook, so each entry
# references only its initramfs image. The cmdline mirrors a known-good config:
#   rd.luks.name=<LUKS partition UUID>=<mapper>  (initramfs `encrypt` hook unlocks it)
#   root=/dev/mapper/<mapper> rootflags=subvol=/@ rw
source "$(dirname "$0")/../lib/common.sh"

CONF="$(dirname "$0")/install.conf"
[ -f "$CONF" ] || { warn "no $CONF — copy install.conf.example to install.conf first"; exit 1; }
# shellcheck disable=SC1090
source "$CONF"
: "${DISK:?set DISK in install.conf}"
: "${CRYPT_NAME:?set CRYPT_NAME in install.conf}"
: "${TARGET:?set TARGET in install.conf}"

part() { case "$1" in *[0-9]) echo "${1}p${2}" ;; *) echo "${1}${2}" ;; esac; }
LUKS_DEV="$(part "$DISK" 2)"

# --- checks ---------------------------------------------------------------
[ -d "$TARGET/usr/share/limine" ] || { warn "$TARGET/usr/share/limine missing — add 'limine' to pacstrap"; exit 1; }
mountpoint -q "$TARGET/boot" || { warn "$TARGET/boot is not a mountpoint — mount the ESP there (btrfs-layout.sh) first"; exit 1; }
[ -f "$TARGET/boot/vmlinuz-linux" ] || warn "no $TARGET/boot/vmlinuz-linux yet — did pacstrap install the 'linux' kernel?"

luks_uuid="$(blkid -s UUID -o value "$LUKS_DEV")"
[ -n "$luks_uuid" ] || { warn "couldn't read a LUKS UUID from $LUKS_DEV — is it the LUKS partition?"; exit 1; }
CMDLINE="rd.luks.name=${luks_uuid}=${CRYPT_NAME} root=/dev/mapper/${CRYPT_NAME} rootflags=subvol=/@ rw"

# --- copy the limine UEFI binary to the ESP (removable fallback path) -----
# \EFI\BOOT\BOOTX64.EFI boots on any UEFI even with no NVRAM entry; the
# efibootmgr entry below just gives it a name in the firmware boot menu.
log "Installing limine BOOTX64.EFI -> ESP:/EFI/BOOT/BOOTX64.EFI"
install -Dm644 "$TARGET/usr/share/limine/BOOTX64.EFI" "$TARGET/boot/EFI/BOOT/BOOTX64.EFI"

# --- limine.conf at the ESP root ------------------------------------------
log "Writing $TARGET/boot/limine.conf"
cat > "$TARGET/boot/limine.conf" <<EOF
timeout: 5
default_entry: 1

/Arch Linux
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: $CMDLINE
    module_path: boot():/initramfs-linux.img

/Arch Linux (LTS)
    protocol: linux
    path: boot():/vmlinuz-linux-lts
    cmdline: $CMDLINE
    module_path: boot():/initramfs-linux-lts.img
EOF

# --- UEFI boot entry (idempotent) -----------------------------------------
if [ -x "$TARGET/usr/bin/efibootmgr" ]; then
    if arch-chroot "$TARGET" efibootmgr 2>/dev/null | grep -q ' Limine$'; then
        log "efibootmgr 'Limine' entry already present"
    else
        log "Creating UEFI boot entry 'Limine' (-> \\EFI\\BOOT\\BOOTX64.EFI on $DISK part 1)"
        arch-chroot "$TARGET" efibootmgr --create --disk "$DISK" --part 1 \
            --label "Limine" --loader '\EFI\BOOT\BOOTX64.EFI' --unicode
    fi
else
    warn "efibootmgr not installed in target; relying on the removable \\EFI\\BOOT\\BOOTX64.EFI fallback"
fi

log "limine installed. cmdline: $CMDLINE"
log "Re-run this after adding/removing kernels to refresh limine.conf."
