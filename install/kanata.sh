#!/usr/bin/env bash
# Kanata keyboard remapper (home-row mods). Installs kanata from the AUR, drops
# our config at /etc/kanata.kbd, installs a systemd unit pointing at it, and
# enables the service. The config and unit live in install/kanata/ next to this
# script. (Currently AUR-only, so Arch-only; cross-distro install is TODO.)
source "$(dirname "$0")/../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"

# kanata is AUR-only; aur_install builds it with makepkg (no-op if present).
aur_install kanata

# Pick the per-machine config. Each recognized machine pins kanata to its own
# built-in keyboard (linux-dev) so external keyboards are left untouched; the
# shared home-row mods come from kanata-common.kbd. Unknown machines fall back
# to the generic config, which grabs all keyboards.
config=kanata.kbd
if host_is "X1 Carbon"; then
    config=kanata.carbon-x1.kbd
elif host_is "X202EV"; then   # ASUS X202EV (product_family is just "X", so match the model)
    config=kanata.asus.kbd
fi
log "Using kanata config: $config"

# Config (+ the shared mods it includes) and our service unit into the system.
# The active config installs as /etc/kanata.kbd; kanata-common.kbd sits beside
# it so the (include "kanata-common.kbd") resolves. install_system_file is a
# no-op when unchanged, so re-runs are quiet.
install_system_file "$HERE/kanata/$config"            /etc/kanata.kbd
install_system_file "$HERE/kanata/kanata-common.kbd"  /etc/kanata-common.kbd
install_system_file "$HERE/kanata/kanata.service"     /etc/systemd/system/kanata.service

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling kanata.service"
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now kanata.service
else
    warn "systemctl not available; enable kanata.service manually"
fi
