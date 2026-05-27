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

# kwallet auto-unlock at login. SDDM ships a default /etc/pam.d/sddm; append the
# two kwallet hooks once (don't rewrite the file, so we keep the package's
# version-specific stack intact). pam_kwallet_init (spawned from niri's
# config.kdl) reads PAM_KWALLET5_LOGIN from this stack to unlock the wallet so
# NetworkManager gets wifi PSKs without re-prompting.
PAM_FILE=/etc/pam.d/sddm
if [ -f "$PAM_FILE" ]; then
    if ! $SUDO grep -q 'pam_kwallet5.so' "$PAM_FILE"; then
        log "Adding kwallet PAM hooks to $PAM_FILE"
        printf '\n# arch-niri: kwallet auto-unlock at login (NetworkManager wifi secrets).\nauth     optional   pam_kwallet5.so\nsession  optional   pam_kwallet5.so auto_start\n' \
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
