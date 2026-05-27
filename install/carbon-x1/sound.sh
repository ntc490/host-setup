#!/usr/bin/env bash
# Audio for the X1 Carbon: ALSA userspace tools + Sound Open Firmware (the
# DSP firmware modern ThinkPad codecs load at boot). (Run via the carbon-x1
# group, which has already gated on Arch + X1 Carbon hardware.)
#
# Starting point — extend with whatever this machine actually needs
# (pipewire/wireplumber, codec quirks, etc.).
source "$(dirname "$0")/../../lib/common.sh"

install_tool alsa-utils
install_tool sof-firmware
