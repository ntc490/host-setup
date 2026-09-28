#!/usr/bin/env bash
# Create the btrfs subvolume layout and mount the target tree under $TARGET,
# ready for pacstrap + genfstab. Run from the Arch ISO, AFTER you have:
#   - partitioned $DISK (ESP + LUKS partition),
#   - opened the LUKS container as /dev/mapper/$CRYPT_NAME, and
#   - run `mkfs.btrfs` on that mapper device and `mkfs.fat -F32` on the ESP.
# See docs/arch-install.md for the surrounding steps.
#
# This script is NOT destructive to data the way mkfs is: it only creates
# subvolumes on the (freshly made) btrfs and mounts things. It is idempotent —
# existing subvolumes are left alone and re-running just remounts.
#
# Layout (top-level subvolumes, so the snapshot store and volatile dirs are
# independent of any @ rollback):
#   @           -> /            (system root, the thing snapper snapshots)
#   @home       -> /home
#   @root       -> /root
#   @srv        -> /srv
#   @cache      -> /var/cache   } excluded from root snapshots: churny / volatile
#   @tmp        -> /var/tmp     }
#   @log        -> /var/log     } kept across rollbacks (logs explain the rollback)
#   @snapshots  -> /.snapshots  (snapper's store; adopted by install/snapper.sh)
# Note /var/lib is deliberately NOT split out — it stays in @ so the pacman DB
# is captured in the same snapshot as /usr and /etc (consistent rollbacks).
source "$(dirname "$0")/../lib/common.sh"

CONF="$(dirname "$0")/install.conf"
if [ ! -f "$CONF" ]; then
    warn "no $CONF — copy install.conf.example to install.conf and edit it first"
    exit 1
fi
# shellcheck disable=SC1090
source "$CONF"

: "${DISK:?set DISK in install.conf}"
: "${CRYPT_NAME:?set CRYPT_NAME in install.conf}"
: "${TARGET:?set TARGET in install.conf}"
: "${BTRFS_OPTS:?set BTRFS_OPTS in install.conf}"

ROOT_DEV="/dev/mapper/$CRYPT_NAME"

# part <disk> <n> — partition node, handling nvme/mmc (p-suffixed) vs sd* naming.
part() {
    case "$1" in
        *[0-9]) echo "${1}p${2}" ;;
        *)      echo "${1}${2}" ;;
    esac
}
ESP_DEV="$(part "$DISK" 1)"

# Subvolume -> mountpoint (relative to $TARGET; @ is the root itself).
SUBVOLS=(@ @home @root @srv @cache @tmp @log @snapshots)
declare -A MP=(
    [@]="" [@home]="home" [@root]="root" [@srv]="srv"
    [@cache]="var/cache" [@tmp]="var/tmp" [@log]="var/log" [@snapshots]=".snapshots"
)

# --- sanity checks --------------------------------------------------------
[ -b "$ROOT_DEV" ] || { warn "$ROOT_DEV is not a block device — open the LUKS container first"; exit 1; }
if [ "$(blkid -o value -s TYPE "$ROOT_DEV" 2>/dev/null)" != "btrfs" ]; then
    warn "$ROOT_DEV is not btrfs — run mkfs.btrfs on it first"
    exit 1
fi
[ -b "$ESP_DEV" ] || warn "$ESP_DEV not found; will skip mounting the ESP (mount it at $TARGET/boot yourself)"

log "Target: $ROOT_DEV (btrfs) + ESP $ESP_DEV -> $TARGET"

# --- create subvolumes on the btrfs top-level (subvolid=5) ----------------
top="$(mktemp -d)"
mount -o subvolid=5 "$ROOT_DEV" "$top"
for sv in "${SUBVOLS[@]}"; do
    if [ -e "$top/$sv" ]; then
        log "subvolume $sv already exists — leaving it"
    else
        log "creating subvolume $sv"
        btrfs subvolume create "$top/$sv" >/dev/null
    fi
done
umount "$top"
rmdir "$top"

# --- mount the tree -------------------------------------------------------
mount_sv() {
    local sv=$1 dir=$2
    mkdir -p "$dir"
    mountpoint -q "$dir" && { log "$dir already mounted"; return 0; }
    log "mounting $sv -> $dir"
    mount -o "${BTRFS_OPTS},subvol=/$sv" "$ROOT_DEV" "$dir"
}

# @ first (it's the root every other mountpoint sits under), then the rest.
mount_sv "@" "$TARGET"
for sv in "${SUBVOLS[@]}"; do
    [ "$sv" = "@" ] && continue
    mount_sv "$sv" "$TARGET/${MP[$sv]}"
done
chmod 750 "$TARGET/.snapshots"

# ESP at $TARGET/boot (kernels/initramfs live on the ESP in this layout).
if [ -b "$ESP_DEV" ]; then
    mkdir -p "$TARGET/boot"
    if mountpoint -q "$TARGET/boot"; then
        log "$TARGET/boot already mounted"
    else
        log "mounting ESP $ESP_DEV -> $TARGET/boot"
        mount "$ESP_DEV" "$TARGET/boot"
    fi
fi

log "Layout mounted. Verify, then pacstrap:"
findmnt -R "$TARGET"
