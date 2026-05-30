#!/usr/bin/env bash
# Wallpaper collection: clones the personal wallpaper repo into ~/Wallpaper.
# Just *content* (the curated images) and machine-agnostic, so it's a top-level
# module usable on any system. On the niri desktop ~/Wallpaper is consumed by
# niri's rotation ($HOME/Wallpaper via scripts/wallpaper-rotate.sh), the hyprlock
# background, and the sddm greeter theme; the awww daemon that actually displays
# and rotates them is the separate niri-only `awww` member. (The niri group
# pulls this in via a thin wrapper at install/gui/niri/wallpaper.sh.)
#
# The repo is public, so it clones over HTTPS — no SSH key needed for the
# read-only fetch this does. To push changes, repoint origin at the SSH URL:
#   git -C ~/Wallpaper remote set-url origin git@github.com:ntc490/wallpaper2.git
# (or push from a separate clone). A failed fetch only warns; it won't abort.
source "$(dirname "$0")/../lib/common.sh"

WALLPAPER_REPO="https://github.com/ntc490/wallpaper2.git"
WALLPAPER_DIR="$HOME/Wallpaper"

# clone_or_update clones on first run, `git pull --rebase` on later runs.
if clone_or_update "$WALLPAPER_REPO" "$WALLPAPER_DIR"; then
    log "Wallpaper collection ready at $WALLPAPER_DIR"
else
    warn "wallpaper: couldn't fetch $WALLPAPER_REPO into $WALLPAPER_DIR"
    warn "  (network/repo access issue; re-run later: ./setup.sh wallpaper)"
fi
