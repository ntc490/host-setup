#!/usr/bin/env bash
# Wayland clipboard + history: wl-clipboard (wl-copy/wl-paste) and cliphist. niri
# spawns two `wl-paste --watch cliphist store` watchers at startup; Mod+Y picks
# from history. No config files.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool wl-clipboard
install_tool cliphist
