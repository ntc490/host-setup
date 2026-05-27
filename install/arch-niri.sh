#!/usr/bin/env bash
# arch-niri: the niri Wayland desktop, as an Arch-only GROUP (like carbon-x1 and
# dev-tools). Gates on Arch, then runs each member in install/gui/niri/ in a
# deliberate order: the compositor core first, then the session pieces, with
# the greeter (which changes the login path) last.
#
# Note: ThinkPad power management (tlp) is NOT here — it lives in the carbon-x1
# group, since it's hardware-specific.
#
# This group does NOT install emacs, kitty, or the ja_JP.UTF-8 locale — those
# are their own host-setup modules and the niri configs assume they're present.
#
# Off by default: listed commented-out in setup.sh. Run explicitly with
# `./setup.sh arch-niri`. The members are not individually runnable via
# `./setup.sh <name>` (setup.sh only resolves top-level install/<name>.sh); run
# the group, or execute a member script directly.
source "$(dirname "$0")/../lib/common.sh"

if [ "$DISTRO_FAMILY" != "arch" ]; then
    warn "arch-niri: Arch-only module; skipping on $DISTRO_ID"
    exit 0
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
NIRI_DIR="$HERE/gui/niri"

# Explicit order (not a glob): the greeter must run last regardless of sort.
MEMBERS=(
    niri-core
    portals
    bar
    launcher
    notifications
    idle-lock
    wallpaper   # clones the wallpaper image collection into ~/Wallpaper
    awww        # wallpaper daemon; displays/rotates the images cloned above
    clipboard
    screenshot
    hardware-controls
    input-method
    fonts
    secrets
    polkit      # polkit auth agent (needed for GUI privilege prompts + fprintd enroll)
    greeter     # LAST: switches the display manager to sddm
)

for m in "${MEMBERS[@]}"; do
    member="$NIRI_DIR/${m}.sh"
    if [ ! -x "$member" ]; then
        warn "arch-niri: member not found or not executable: $m (skipping)"
        continue
    fi
    log "----- arch-niri/$m -----"
    "$member"
done

log "arch-niri complete. The niri session is selectable at the sddm login"
log "after the next reboot."
