#!/usr/bin/env bash
# Hardware control helpers used by niri's media/brightness key binds:
#   brightnessctl - backlight, pavucontrol - audio mixer GUI,
#   playerctl - MPRIS media control.
# (Volume/mute keys use wpctl from the PipeWire stack, installed elsewhere.)
source "$(dirname "$0")/../../../lib/common.sh"

install_tool brightnessctl
install_tool pavucontrol
install_tool playerctl
