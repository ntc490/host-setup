#!/usr/bin/env bash
# Polkit authentication agent for the niri session. Without an agent, anything
# governed by polkit is silently DENIED because there's nothing to show the auth
# prompt — mounting disks, NetworkManager system changes, and notably fprintd
# enrollment (net.reactivated.fprint.device.enroll is auth_self_keep, so it must
# prompt for your password). That denial is exactly what blocks fingerprint
# enrollment; see install/carbon-x1/fingerprint.sh.
#
# polkit-kde-agent matches this setup's existing Qt/KDE pieces (sddm + kwallet),
# so it pulls in little beyond what's already present. niri does not run XDG
# autostart .desktop files, so the agent is launched explicitly via
# spawn-at-startup in the niri config (stowed from dotfiles/niri).
# (Run via the arch-niri group, which has already gated on Arch.)
source "$(dirname "$0")/../../../lib/common.sh"

install_tool polkit-kde-agent

log "polkit-kde-agent installed. It autostarts with niri (spawn-at-startup);"
log "log out/in (or run /usr/lib/polkit-kde-authentication-agent-1 &) to start it now."
