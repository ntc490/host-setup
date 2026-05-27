#!/usr/bin/env bash
# OpenSSH server: install it, make sure host keys exist, and enable+start the
# daemon. Cross-distro: package and service names differ (see below).
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool openssh   # arch: openssh; debian/rhel: openssh-server

# Generate any missing host keys (idempotent — only creates what's absent).
# Arch's sshd.service in particular doesn't do this for you.
if command -v ssh-keygen >/dev/null 2>&1; then
    log "Ensuring SSH host keys exist (ssh-keygen -A)"
    $SUDO ssh-keygen -A
fi

# The unit is named differently across distros: Debian calls it ssh, the rest sshd.
case "$DISTRO_FAMILY" in
    debian) svc=ssh ;;
    *)      svc=sshd ;;
esac

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling $svc.service"
    $SUDO systemctl enable --now "$svc"
else
    warn "systemctl not available; start the ssh server manually ($svc)"
fi
