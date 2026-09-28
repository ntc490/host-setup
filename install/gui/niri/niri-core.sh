#!/usr/bin/env bash
# niri: the scrollable-tiling Wayland compositor itself + its config. The niri
# stow package also carries the helper scripts the config spawns
# (scripts/lock.sh, scripts/wallpaper-rotate.sh). Run first in the arch-niri
# group — the other members layer onto a working compositor.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool niri
stow_pkg niri
