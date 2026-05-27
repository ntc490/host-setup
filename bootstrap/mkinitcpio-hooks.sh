#!/usr/bin/env bash
# Set the mkinitcpio HOOKS for an encrypted (LUKS) btrfs root and regenerate the
# initramfs. Run from the Arch ISO after pacstrap; edits $TARGET's config and
# regenerates via arch-chroot. See docs/arch-install.md.
#
# The ordering that matters:
#   keyboard + keymap  BEFORE encrypt  (so you can type the LUKS passphrase)
#   block              BEFORE encrypt  (so the LUKS partition is visible)
#   encrypt            BEFORE filesystems  (open the mapper before mounting root)
# btrfs needs no special hook — `filesystems` handles it — and `fsck` is dropped
# because btrfs has no boot-time fsck. Microcode is folded into the initramfs by
# the `microcode` hook, so the bootloader only references one initramfs image.
source "$(dirname "$0")/../lib/common.sh"

CONF="$(dirname "$0")/install.conf"
[ -f "$CONF" ] || { warn "no $CONF — copy install.conf.example to install.conf first"; exit 1; }
# shellcheck disable=SC1090
source "$CONF"
: "${TARGET:?set TARGET in install.conf}"

MKICFG="$TARGET/etc/mkinitcpio.conf"
[ -f "$MKICFG" ] || { warn "$MKICFG not found — pacstrap the base system first"; exit 1; }

HOOKS_LINE='HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems)'

log "Setting HOOKS in $MKICFG"
if grep -qE '^HOOKS=' "$MKICFG"; then
    sed -i -E "s|^HOOKS=.*|$HOOKS_LINE|" "$MKICFG"
else
    printf '%s\n' "$HOOKS_LINE" >> "$MKICFG"
fi
log "HOOKS now: $(grep -E '^HOOKS=' "$MKICFG")"

log "Regenerating initramfs (mkinitcpio -P) in $TARGET"
arch-chroot "$TARGET" mkinitcpio -P
