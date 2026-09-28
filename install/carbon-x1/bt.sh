#!/usr/bin/env bash
# Bluetooth stack for the X1 Carbon: bluez + tools + the blueman GUI applet,
# with the bluetooth service enabled. (Run via the carbon-x1 group, which has
# already gated on Arch + X1 Carbon hardware.)
source "$(dirname "$0")/../../lib/common.sh"

install_tool bluez
install_tool bluez-utils
install_tool blueman

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling bluetooth.service"
    $SUDO systemctl enable --now bluetooth.service
else
    warn "systemctl not available; enable bluetooth.service manually"
fi
