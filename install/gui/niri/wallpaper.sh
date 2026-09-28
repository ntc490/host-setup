#!/usr/bin/env bash
# Wallpaper collection for the niri desktop — the images (~/Wallpaper) are wanted
# on any machine, so the actual logic lives in the top-level wallpaper module.
# This thin wrapper keeps `./setup.sh arch-niri` self-contained (clones the
# collection even when a full ./setup.sh hasn't run first). The awww daemon that
# displays/rotates them is the separate niri `awww` member.
source "$(dirname "$0")/../../../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/../../wallpaper.sh"
