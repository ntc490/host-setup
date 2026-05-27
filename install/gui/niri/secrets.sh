#!/usr/bin/env bash
# Secret storage + networking. Under a non-KDE niri session we still use KWallet
# as the Secret Service so NetworkManager (wifi PSKs), SSH, etc. have somewhere
# to store secrets; libsecret is the client lib apps talk to. The kwallet PAM
# auto-unlock hook is set up by the greeter module (it belongs to the login PAM
# stack, /etc/pam.d/sddm). Here we just install the pieces and enable NetworkManager.
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
