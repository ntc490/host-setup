#!/usr/bin/env bash
# pacman-config: quality-of-life + build-speed tweaks for pacman & makepkg (Arch).
# Idempotent in-place edits, NOT a full-file replace -- pacman ships .pacnew
# updates to these files, so we only flip the specific lines we care about and
# leave everything else (and future upstream changes) alone. Re-runs are quiet.
#
#   /etc/pacman.conf   : Color, ILoveCandy (the pac-man progress bar), VerbosePkgLists
#   /etc/makepkg.conf  : MAKEFLAGS="-j$(nproc)" so AUR builds use every core
#
# (ccache and PKGEXT='.pkg.tar' are deliberately left out -- add them here if you
# want them. ParallelDownloads is already on by default, so we don't touch it.)
source "$(dirname "$0")/../lib/common.sh"

[ "$DISTRO_FAMILY" = arch ] || { warn "pacman-config: Arch-only; skipping on $DISTRO_ID"; exit 0; }

PACMAN_CONF=/etc/pacman.conf
MAKEPKG_CONF=/etc/makepkg.conf

# ensure_flag <flag> -- enable a boolean [options] directive in pacman.conf. If
# it's already uncommented, no-op; if present commented (`#Color`), uncomment in
# place; if absent entirely (the ILoveCandy easter egg isn't in the stock file),
# add it just under the [options] header.
ensure_flag() {
    local flag=$1
    if grep -qE "^[[:space:]]*${flag}[[:space:]]*$" "$PACMAN_CONF"; then
        return 0
    elif grep -qE "^[[:space:]]*#[[:space:]]*${flag}[[:space:]]*$" "$PACMAN_CONF"; then
        $SUDO sed -i -E "s/^[[:space:]]*#[[:space:]]*(${flag})[[:space:]]*$/\1/" "$PACMAN_CONF"
        log "pacman.conf: enabled $flag"
    else
        $SUDO sed -i "/^\[options\]/a ${flag}" "$PACMAN_CONF"
        log "pacman.conf: added $flag"
    fi
}

# set_makeflags -- set MAKEFLAGS="-j$(nproc)" in makepkg.conf, converging whether
# the line is currently the stock commented `#MAKEFLAGS="-j2"`, set to something
# else, or absent. The literal $(nproc) is written into the file so makepkg
# evaluates it per-machine at build time (right core count everywhere).
set_makeflags() {
    local want='MAKEFLAGS="-j$(nproc)"'
    if grep -qxF "$want" "$MAKEPKG_CONF"; then
        return 0                                   # already exactly right
    elif grep -qE '^[[:space:]]*MAKEFLAGS=' "$MAKEPKG_CONF"; then
        $SUDO sed -i -E "s|^[[:space:]]*MAKEFLAGS=.*|${want}|" "$MAKEPKG_CONF"
        log "makepkg.conf: set ${want}"
    elif grep -qE '^[[:space:]]*#[[:space:]]*MAKEFLAGS=' "$MAKEPKG_CONF"; then
        $SUDO sed -i -E "s|^[[:space:]]*#[[:space:]]*MAKEFLAGS=.*|${want}|" "$MAKEPKG_CONF"
        log "makepkg.conf: set ${want}"
    else
        printf '%s\n' "$want" | $SUDO tee -a "$MAKEPKG_CONF" >/dev/null
        log "makepkg.conf: appended ${want}"
    fi
}

if [ -f "$PACMAN_CONF" ]; then
    ensure_flag Color
    ensure_flag ILoveCandy
    ensure_flag VerbosePkgLists
else
    warn "pacman-config: $PACMAN_CONF missing; skipping pacman.conf tweaks"
fi

if [ -f "$MAKEPKG_CONF" ]; then
    set_makeflags
else
    warn "pacman-config: $MAKEPKG_CONF missing; skipping makepkg.conf tweaks"
fi

log "pacman-config done (takes effect on the next pacman/makepkg invocation)."
