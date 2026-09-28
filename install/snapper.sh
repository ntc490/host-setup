#!/usr/bin/env bash
# Snapper btrfs snapshots (Arch-only). Wires snapper's `root` config against a
# top-level @snapshots subvolume (adopted if this machine's layout already has
# one, created if not), installs snap-pac for automatic pre/post snapshots around
# pacman transactions, and enables the timeline + cleanup timers.
#
# No bootloader integration: snapshots are taken and pruned, but they are NOT
# exposed as boot entries (the bootloader here is limine). Recovery is by
# mounting / rolling back a snapshot from a live environment.
#
# The fiddly bit: `snapper create-config` insists on creating its *own*
# .snapshots subvolume and won't reuse one. Our layout already ships @snapshots,
# so we let create-config make its throwaway, delete that, and mount the real
# @snapshots at /.snapshots via fstab instead. This is only safe because
# @snapshots is not mounted at /.snapshots during create-config, so the
# subvolume we delete is unambiguously the throwaway, never @snapshots.
#
# Gated: Arch + btrfs root (no-ops cleanly otherwise, so it's safe to leave in
# the default ALL run). The @snapshots subvolume is adopted if present, created
# as a top-level subvolume if not.
source "$(dirname "$0")/../lib/common.sh"
require_supported

SNAP_DIR=/.snapshots

if [ "$DISTRO_FAMILY" != "arch" ]; then
    warn "snapper: Arch-only module; skipping on $DISTRO_ID"
    exit 0
fi

# Root must be btrfs, or there's nothing to snapshot.
root_fstype="$(findmnt -no FSTYPE / 2>/dev/null || true)"
if [ "$root_fstype" != "btrfs" ]; then
    warn "snapper: / is not btrfs (got '${root_fstype:-unknown}'); skipping"
    exit 0
fi

# Ensure a top-level @snapshots subvolume exists. This machine's layout already
# ships one; on a fresh install it may not. We make it a *top-level* subvolume
# (sibling of @, @home, ...) so the snapshot store persists independently of any
# @ rollback — which means mounting the btrfs root (subvolid=5) to reach it.
if ! $SUDO btrfs subvolume list / | grep -qE '[[:space:]]path[[:space:]]+@snapshots$'; then
    dev="$(findmnt -no SOURCE / | sed 's/\[.*//')"   # strip the [/@] subvol suffix
    if [ -z "$dev" ]; then
        warn "snapper: couldn't find the btrfs device for /; create an @snapshots subvolume by hand"
        exit 1
    fi
    top="$(mktemp -d)"
    log "Creating top-level @snapshots subvolume on $dev"
    $SUDO mount -o subvolid=5 "$dev" "$top"
    $SUDO btrfs subvolume create "$top/@snapshots" || { $SUDO umount "$top"; rmdir "$top"; exit 1; }
    $SUDO umount "$top"
    rmdir "$top"
fi

install_tool snapper
install_tool snap-pac   # pre/post snapshots on every pacman transaction

# ---------------------------------------------------------------------------
# Create the `root` config, swapping in the existing @snapshots subvolume.
# ---------------------------------------------------------------------------
if $SUDO test -e /etc/snapper/configs/root; then
    log "snapper 'root' config already present"
else
    # create-config refuses to run if /.snapshots already exists. On a clean
    # machine it doesn't. If it's *mounted* but we have no config, something is
    # half-set-up: refuse rather than risk deleting the real @snapshots below.
    if findmnt "$SNAP_DIR" >/dev/null 2>&1; then
        warn "snapper: $SNAP_DIR is mounted but no root config exists — unexpected half-setup."
        warn "Unmount $SNAP_DIR (umount $SNAP_DIR) and re-run; refusing to auto-fix to protect @snapshots."
        exit 1
    fi
    if [ -e "$SNAP_DIR" ]; then
        $SUDO rmdir "$SNAP_DIR" 2>/dev/null || {
            warn "snapper: $SNAP_DIR exists and isn't an empty dir; inspect it by hand."
            exit 1
        }
    fi

    log "Creating snapper 'root' config for /"
    $SUDO snapper -c root create-config /

    # create-config just made its own fresh .snapshots subvolume. Delete that
    # throwaway (@snapshots is not mounted here, so this can only be the new one)
    # and put the pre-existing @snapshots in its place.
    log "Replacing the auto-created .snapshots with the existing @snapshots subvolume"
    $SUDO btrfs subvolume delete "$SNAP_DIR"
    $SUDO mkdir -p "$SNAP_DIR"
fi

# ---------------------------------------------------------------------------
# Mount @snapshots at /.snapshots (idempotent: fstab entry + active mount).
# ---------------------------------------------------------------------------
if ! grep -qE '[[:space:]]/\.snapshots[[:space:]]' /etc/fstab; then
    root_uuid="$(findmnt -no UUID / 2>/dev/null || true)"
    if [ -z "$root_uuid" ]; then
        warn "snapper: couldn't determine root fs UUID; add @snapshots -> /.snapshots to /etc/fstab by hand"
    else
        log "Adding @snapshots -> /.snapshots to /etc/fstab"
        printf 'UUID=%s\t/.snapshots\tbtrfs\trw,relatime,ssd,space_cache=v2,subvol=/@snapshots\t0 0\n' \
            "$root_uuid" | $SUDO tee -a /etc/fstab >/dev/null
        $SUDO systemctl daemon-reload 2>/dev/null || true   # let systemd see the new mount
    fi
fi

if ! findmnt "$SNAP_DIR" >/dev/null 2>&1; then
    log "Mounting $SNAP_DIR"
    $SUDO mount "$SNAP_DIR"
fi
$SUDO chmod 750 "$SNAP_DIR"   # snapper expects /.snapshots to be 0750

# ---------------------------------------------------------------------------
# Retention + access policy, and the timers that enforce it.
# ---------------------------------------------------------------------------
log "Tuning snapper 'root' retention"
$SUDO snapper -c root set-config \
    TIMELINE_CREATE=yes \
    TIMELINE_CLEANUP=yes \
    NUMBER_CLEANUP=yes \
    NUMBER_LIMIT=10 \
    NUMBER_LIMIT_IMPORTANT=10 \
    TIMELINE_LIMIT_HOURLY=5 \
    TIMELINE_LIMIT_DAILY=7 \
    TIMELINE_LIMIT_WEEKLY=2 \
    TIMELINE_LIMIT_MONTHLY=2 \
    TIMELINE_LIMIT_YEARLY=0 \
    ALLOW_GROUPS=wheel \
    SYNC_ACL=yes

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling snapper timeline + cleanup timers"
    $SUDO systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
else
    warn "systemctl unavailable; enable snapper-timeline.timer / snapper-cleanup.timer manually"
fi

log "snapper set up. Snapshots: snapper -c root list. snap-pac wraps pacman automatically."
