#!/usr/bin/env bash
# waybar status bar + config (workspaces, clock, network, audio, battery, and
# the fcitx5 input-method indicator via scripts/fcitx5-status.sh). niri spawns
# it at startup.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool waybar
stow_pkg waybar
