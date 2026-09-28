#!/usr/bin/env bash
# Secret service + networking. KWallet provides the freedesktop Secret Service
# (org.freedesktop.secrets) under this non-KDE niri session, for libsecret-based
# apps that want somewhere to store their own secrets. NetworkManager does NOT
# use it for wifi — NM keeps wifi PSKs in its own root-only profiles under
# /etc/NetworkManager/system-connections (encrypted at rest by the LUKS root).
# libsecret is the client lib apps talk to. The kwallet PAM auto-unlock hook is
# set up by the greeter module (/etc/pam.d/sddm). Here we just install the pieces
# and enable NetworkManager.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool kwallet
install_tool kwallet-pam
install_tool libsecret
install_tool networkmanager

# kwalletd6 is D-Bus-activated on first secret request, so nothing to enable for
# it. NetworkManager does need its service running.
if command -v systemctl >/dev/null 2>&1; then
    log "Enabling NetworkManager.service"
    $SUDO systemctl enable --now NetworkManager.service
else
    warn "systemctl unavailable; enable NetworkManager.service manually"
fi
