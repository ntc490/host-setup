#!/usr/bin/env bash
# Syncthing: continuous file sync, run as a per-user systemd service.
#
# RUN THIS MANUALLY — it is intentionally NOT in setup.sh's ALL list and not in
# any auto-run group, because it's specific to one machine (this laptop's device
# identity + folders) and the restore step below wants deliberate handling. Run
# it on demand:  ./setup.sh syncthing   (or ./install/syncthing.sh).
#
# SECRETS STAY OUT OF GIT. Syncthing's device identity (cert.pem/key.pem), its
# folder/device config (config.xml, which also embeds the GUI password hash and
# API key), and the GUI TLS cert live ONLY in the state dir below — never in
# this repo. This module installs syncthing and enables the service; it does not
# carry any of those files.
#
# Restore (optional, re-runnable): to keep this machine's device ID and avoid
# re-pairing every device, point SYNCTHING_RESTORE_FROM at a backup / old
# install's state dir:
#   SYNCTHING_RESTORE_FROM=/mnt/home/ncrapo/.local/state/syncthing ./setup.sh syncthing
# Forgot to set it the first time? No problem: syncthing will have generated a
# fresh identity, but re-running WITH the var set stops the service, backs up
# that throwaway identity, and swaps in the restored one — no manual cleanup.
# Only the identity + config are restored (not the index DB, which rebuilds).
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool syncthing

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/syncthing"
RESTORE_FROM="${SYNCTHING_RESTORE_FROM:-}"

# restore_identity <src-state-dir> — swap the device identity + config into our
# state dir from a backup, so syncthing adopts that identity instead of (or
# instead of keeping) a freshly generated one. Re-runnable: stops the service
# first and backs up any existing identity rather than refusing.
restore_identity() {
    local src=$1 f
    if [ ! -d "$src" ]; then
        warn "syncthing: restore source '$src' not found; skipping restore"
        return 1
    fi

    # Stop the service if it's running, so it neither holds the files nor
    # rewrites config.xml after we restore.
    if systemctl --user is-active --quiet syncthing.service 2>/dev/null; then
        log "syncthing: stopping the service to swap in the restored identity"
        systemctl --user stop syncthing.service
    fi

    mkdir -p "$STATE_DIR"
    chmod 700 "$STATE_DIR"

    # Back up anything already here (e.g. a throwaway identity from a previous
    # run that forgot SYNCTHING_RESTORE_FROM) before overwriting it.
    if [ -f "$STATE_DIR/config.xml" ]; then
        local bak="$STATE_DIR/pre-restore-$(date +%Y%m%d%H%M%S)"
        log "syncthing: existing identity found; backing it up to $bak"
        mkdir -p "$bak"
        for f in cert.pem key.pem config.xml https-cert.pem https-key.pem; do
            [ -e "$STATE_DIR/$f" ] && mv "$STATE_DIR/$f" "$bak/"
        done
    fi

    # Public certs: 0644. Private keys + config (has password hash/API key): 0600.
    for f in cert.pem https-cert.pem; do
        [ -f "$src/$f" ] && { log "syncthing: restoring $f"; install -m 644 "$src/$f" "$STATE_DIR/$f"; }
    done
    for f in key.pem https-key.pem config.xml; do
        [ -f "$src/$f" ] && { log "syncthing: restoring $f"; install -m 600 "$src/$f" "$STATE_DIR/$f"; }
    done

    [ -f "$STATE_DIR/config.xml" ] \
        || warn "syncthing: no config.xml in '$src' — a fresh identity will be generated on start"
}

[ -n "$RESTORE_FROM" ] && restore_identity "$RESTORE_FROM"

# Per-user service (no sudo) — runs within your login session. For a headless or
# always-on box, also run: loginctl enable-linger "$USER"  (so it runs logged out).
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    log "Enabling syncthing.service (user)"
    systemctl --user enable --now syncthing.service
    log "Web UI: http://127.0.0.1:8384"
    [ -z "$RESTORE_FROM" ] && log "Tip: to adopt a previous device identity, re-run with SYNCTHING_RESTORE_FROM=<old state dir>"
else
    warn "no systemd --user session here; enable later with:"
    warn "  systemctl --user enable --now syncthing.service"
fi
