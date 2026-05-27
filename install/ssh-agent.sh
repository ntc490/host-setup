#!/usr/bin/env bash
# Enable the user ssh-agent on Arch. openssh ships a socket-activated
# ssh-agent.socket user unit; we point SSH_AUTH_SOCK at it and enable it.
# Arch-only — other distros leave the agent to the desktop session.
source "$(dirname "$0")/../lib/common.sh"

[ "$DISTRO_FAMILY" = arch ] || { warn "ssh-agent: Arch-only; skipping on $DISTRO_ID"; exit 0; }

# The unit reads SSH_AUTH_SOCK from the environment; environment.d sets it at login.
mkdir -p ~/.config/environment.d
printf 'SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/ssh-agent.socket\n' > ~/.config/environment.d/ssh-agent.conf

# --user, so no sudo. Skip cleanly if there's no user session (e.g. over SSH).
if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user enable --now ssh-agent.socket
else
    warn "no systemd --user session; ssh-agent.socket will start at next login"
fi
