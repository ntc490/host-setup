#!/usr/bin/env bash
# Login greeter: SDDM. Runs LAST in the arch-niri group because it changes the
# boot login path. The niri session is selectable at login because the niri
# package ships /usr/share/wayland-sessions/niri.desktop.
#
# Why SDDM (not greetd + gtkgreet): gtkgreet draws its login surface via
# gtk-layer-shell, and the current Arch versions have drifted out of sync —
# gtkgreet 0.8 maps its window before initializing layer-shell, which trips
#   custom_shell_surface_init: assertion '!gtk_widget_get_mapped (...)' failed
# in gtk-layer-shell 0.10. The half-initialized layer surface then hits a
# Wayland protocol error on the next roundtrip, libwayland abort()s the greeter,
# and greetd restart-loops without ever starting a session (grabbing vt1 each
# time). SDDM's Xorg greeter doesn't touch gtk-layer-shell at all — the niri
# session it launches is still pure Wayland — and it's the display manager this
# machine ran before the niri migration.
#
# We use `enable` (not `enable --now`) so the switch takes effect on the next
# reboot, leaving a rollback window:
#   from a TTY:  sudo systemctl disable sddm   (then re-enable your old DM)
source "$(dirname "$0")/../../../lib/common.sh"

# SDDM pulls in xorg-server/xorg-xauth as hard deps (its greeter runs on Xorg).
install_tool sddm

# qt6-5compat ships Qt5Compat.GraphicalEffects, which our theme's Main.qml uses
# for the login card's DropShadow. It is not a hard dep of sddm, so pull it in
# explicitly or the greeter loads with a blank screen (QML import error).
install_tool qt6-5compat

# ---------------------------------------------------------------------------
# Custom greeter theme ("lockscreen"): a dark login styled to match hyprlock
# (Japanese date, big clock, rounded login card). Source lives beside this
# script; copy it into SDDM's system theme dir and select it.
THEME_SRC="$(dirname "$0")/sddm-theme"
THEME_DST=/usr/share/sddm/themes/lockscreen
if [ -d "$THEME_SRC" ]; then
    log "Installing SDDM theme -> $THEME_DST"
    $SUDO rm -rf "$THEME_DST"
    $SUDO mkdir -p "$THEME_DST"
    $SUDO cp -a "$THEME_SRC/." "$THEME_DST/"
    $SUDO chmod -R a+rX "$THEME_DST"

    # background.jpg in the repo is a *symlink* into ~/Wallpaper/raw, so the repo
    # carries no image bytes and swapping the wallpaper is a one-line repoint of
    # the link. cp -a above copied it as a symlink, which is no good: the greeter
    # runs as the unprivileged `sddm` user before login and can't traverse /home
    # (mode 700) to follow it. So replace it with the real, world-readable bytes
    # here — this cp runs as root (via $SUDO), which *can* read through the link.
    if [ -e "$THEME_SRC/background.jpg" ]; then
        $SUDO rm -f "$THEME_DST/background.jpg"
        if $SUDO cp -L "$THEME_SRC/background.jpg" "$THEME_DST/background.jpg"; then
            $SUDO chmod a+r "$THEME_DST/background.jpg"
        else
            warn "could not read $(readlink -f "$THEME_SRC/background.jpg" 2>/dev/null || echo "$THEME_SRC/background.jpg"); greeter background will be blank"
        fi
    fi

    # Select the theme. Use a drop-in under sddm.conf.d so we don't clobber any
    # hand-edited /etc/sddm.conf.
    $SUDO mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=lockscreen\n' \
        | $SUDO tee /etc/sddm.conf.d/10-theme.conf >/dev/null
    log "Selected SDDM theme 'lockscreen' (/etc/sddm.conf.d/10-theme.conf)"
else
    warn "SDDM theme source $THEME_SRC not found; leaving default theme"
fi

# kwallet auto-unlock at login. SDDM ships a default /etc/pam.d/sddm; append the
# two kwallet hooks once (don't rewrite the file, so we keep the package's
# version-specific stack intact). pam_kwallet_init (spawned from niri's
# config.kdl) reads PAM_KWALLET5_LOGIN from this stack to unlock the wallet at
# login, so libsecret apps find an already-unlocked Secret Service.
PAM_FILE=/etc/pam.d/sddm
if [ -f "$PAM_FILE" ]; then
    if ! $SUDO grep -q 'pam_kwallet5.so' "$PAM_FILE"; then
        log "Adding kwallet PAM hooks to $PAM_FILE"
        printf '\n# arch-niri: kwallet auto-unlock at login (Secret Service for libsecret apps).\nauth     optional   pam_kwallet5.so\nsession  optional   pam_kwallet5.so auto_start\n' \
            | $SUDO tee -a "$PAM_FILE" >/dev/null
    else
        log "$PAM_FILE already has kwallet hooks; skipping"
    fi
else
    warn "$PAM_FILE not found; install sddm first. kwallet auto-unlock not configured."
fi

# Make SDDM the display manager. enable (not --now) => effective next reboot.
if command -v systemctl >/dev/null 2>&1; then
    # Drop greetd first: enabling sddm.service rewrites the display-manager.service
    # alias, and we don't want two DMs both claiming it.
    if systemctl is-enabled greetd.service >/dev/null 2>&1; then
        log "Disabling greetd.service (replaced by sddm)"
        $SUDO systemctl disable greetd.service
    fi
    $SUDO systemctl daemon-reload
    log "Enabling sddm.service (effective next reboot)"
    $SUDO systemctl enable sddm.service
    warn "sddm is now the display manager (takes effect on reboot)."
    warn "If graphical login fails, from a TTY run: sudo systemctl disable sddm"
else
    warn "systemctl unavailable; enable sddm.service manually"
fi
