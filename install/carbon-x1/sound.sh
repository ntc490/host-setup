#!/usr/bin/env bash
# Audio for the X1 Carbon. Two layers:
#   1. kernel: sof-firmware — the DSP firmware the SOF driver loads at boot to
#      bring the codec up (so the card appears in /proc/asound/cards).
#   2. userspace: the PipeWire stack apps actually talk to. wireplumber is the
#      session manager that routes devices; pipewire-pulse is the PulseAudio
#      shim apps like Firefox/Chromium use (without it: "Connection refused").
# (Run via the carbon-x1 group, which has already gated on Arch + X1 Carbon.)
source "$(dirname "$0")/../../lib/common.sh"

install_tool alsa-utils
install_tool sof-firmware

install_tool pipewire
install_tool pipewire-pulse   # PulseAudio-compatible socket for Firefox et al.
install_tool wireplumber      # session manager that manages/routes the devices

# The PipeWire user services are socket-activated and start with the graphical
# session, but enable them explicitly so a fresh login is set up. --user, so no
# sudo. Best-effort: skip cleanly if there's no systemd user session (e.g. when
# run over SSH or in a container).
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    log "Enabling pipewire / pipewire-pulse / wireplumber user services"
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service
else
    warn "no systemd --user session here; pipewire services will start at next graphical login"
fi
