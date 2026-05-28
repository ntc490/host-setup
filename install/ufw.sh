#!/usr/bin/env bash
# Host firewall via ufw: default-deny incoming, allow outgoing, with SSH and
# Syncthing opened. ufw is in the Arch/Debian repos and in EPEL on RHEL;
# install_tool skips+warns where it's absent (handle those distros' native
# firewall — e.g. firewalld — yourself). Safe to re-run (rules are idempotent).
#
# SSH is allowed BEFORE the firewall is enabled, so running this over a remote
# session never locks you out.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool ufw

if ! command -v ufw >/dev/null 2>&1; then
    warn "ufw: not installed (not in this distro's repos?); skipping firewall config"
    exit 0
fi

# Capability check: ufw needs working netfilter/iptables to even set a default
# rule. In restricted environments (containers, some sandboxes) the iptables
# init itself fails — skip cleanly rather than abort.
if ! $SUDO ufw status >/dev/null 2>&1; then
    warn "ufw can't initialize netfilter (a container or restricted kernel?); skipping firewall config"
    exit 0
fi

log "Configuring ufw (deny incoming / allow outgoing; SSH + Syncthing open)"
$SUDO ufw default deny incoming
$SUDO ufw default allow outgoing

# SSH (the ssh-server module enables sshd on :22). Open it FIRST.
$SUDO ufw allow 22/tcp

# Syncthing: data (22000 tcp + udp/QUIC) and local discovery (21027/udp).
# Harmless if syncthing isn't installed; needed for local peers + discovery.
$SUDO ufw allow 22000/tcp
$SUDO ufw allow 22000/udp
$SUDO ufw allow 21027/udp

# --force skips the interactive prompt; enabling is idempotent. Tolerate an
# environment without netfilter (e.g. a container) rather than aborting setup.
$SUDO ufw --force enable \
    || { warn "ufw enable failed (no netfilter — a container?); rules set, firewall not active"; exit 0; }

if command -v systemctl >/dev/null 2>&1; then
    $SUDO systemctl enable ufw.service 2>/dev/null \
        || warn "couldn't enable ufw.service (no systemd here?); ufw is enabled but verify it starts on boot"
fi

log "ufw active. Review with: sudo ufw status verbose"
log "  Other incoming services need an explicit: sudo ufw allow <port>/<proto>"
