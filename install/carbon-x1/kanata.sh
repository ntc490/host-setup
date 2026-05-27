#!/usr/bin/env bash
# Kanata keyboard remapper (home-row mods on the X1's built-in keyboard).
# Installs kanata from the AUR, drops our config at /etc/kanata.kbd, installs a
# systemd unit pointing at it, and enables the service. The config and unit live
# next to this script. (Run via the carbon-x1 group: Arch + X1 Carbon gated.)
source "$(dirname "$0")/../../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"

# kanata is AUR-only; aur_install builds it with makepkg (no-op if present).
aur_install kanata

# Config + our own service unit into the system. install_system_file is a no-op
# when unchanged, so re-runs are quiet.
install_system_file "$HERE/kanata.kbd"     /etc/kanata.kbd
install_system_file "$HERE/kanata.service" /etc/systemd/system/kanata.service

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling kanata.service"
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now kanata.service
else
    warn "systemctl not available; enable kanata.service manually"
fi
