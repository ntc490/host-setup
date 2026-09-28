#!/usr/bin/env bash
# Enable the user ssh-agent on Arch. openssh ships a socket-activated
# ssh-agent.socket user unit; we point SSH_AUTH_SOCK at it (via environment.d)
# and enable it. With AddKeysToAgent in ~/.ssh/config, the first ssh/git use
# prompts for the key passphrase once and the agent caches it for the session.
# Arch-only — other distros leave the agent to the desktop session.
source "$(dirname "$0")/../lib/common.sh"

[ "$DISTRO_FAMILY" = arch ] || { warn "ssh-agent: Arch-only; skipping on $DISTRO_ID"; exit 0; }

# SSH_AUTH_SOCK is set by a committed environment.d drop-in (environment stow
# package). It must NOT be written here at runtime: ~/.config/environment.d is a
# stow symlink into this repo, so a write would land back in the repo. stow_pkg
# links the drop-in into place (idempotent; input-method.sh stows this too).
# environment.d vars reach the graphical session — same path the input-method
# vars in this package already take.
stow_pkg environment

# --user, so no sudo. Skip cleanly if there's no user session (e.g. over SSH).
if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user enable --now ssh-agent.socket
else
    warn "no systemd --user session; ssh-agent.socket will start at next login"
fi
