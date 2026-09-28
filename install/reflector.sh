#!/usr/bin/env bash
# reflector: keep pacman's mirrorlist ranked by speed. Arch-only. Installs
# reflector, drops the config the bundled reflector.service/timer reads, enables
# the timer (weekly refresh), and refreshes the mirrorlist once now.
source "$(dirname "$0")/../lib/common.sh"

[ "$DISTRO_FAMILY" = arch ] || { warn "reflector: Arch-only; skipping on $DISTRO_ID"; exit 0; }

HERE="$(cd "$(dirname "$0")" && pwd)"

install_tool reflector

# The reflector.service runs `reflector @/etc/xdg/reflector/reflector.conf`.
install_system_file "$HERE/reflector/reflector.conf" /etc/xdg/reflector/reflector.conf

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling reflector.timer (weekly mirrorlist refresh)"
    $SUDO systemctl enable reflector.timer
    log "Refreshing the mirrorlist now"
    $SUDO systemctl start reflector.service \
        || warn "reflector run failed (offline?); the timer will retry on schedule"
else
    warn "systemctl unavailable; run 'reflector @/etc/xdg/reflector/reflector.conf' manually"
fi
