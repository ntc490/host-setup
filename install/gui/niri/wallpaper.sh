#!/usr/bin/env bash
# awww wallpaper daemon (provides awww + awww-daemon). niri spawns awww-daemon at
# startup and runs scripts/wallpaper-rotate.sh (which calls `awww img`) on a
# timer. The rotate script ships inside the niri stow package, so there's no
# dotfile to stow here.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool awww
