#!/usr/bin/env bash
# Login greeter: greetd running gtkgreet inside cage. Runs LAST in the arch-niri
# group because it changes the boot login path. On this setup there is no prior
# display manager, so enabling greetd is additive; if an sddm unit happens to be
# enabled we disable it too. We use `enable` (not `enable --now`) so the switch
# takes effect on the next reboot, leaving a rollback window:
#   from a TTY:  sudo systemctl disable greetd   (then re-enable your old DM)
source "$(dirname "$0")/../../../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"

install_tool greetd
install_tool greetd-gtkgreet
install_tool cage

# The greetd package creates the unprivileged "greeter" user; add it if missing.
if ! getent passwd greeter >/dev/null 2>&1; then
    log "Creating greeter system user"
    $SUDO useradd --system --no-create-home --shell /usr/bin/nologin \
        --groups video,input greeter || warn "could not create greeter user"
fi

# greetd config: run gtkgreet under cage, listing wayland sessions.
install_system_file "$HERE/greetd-config.toml" /etc/greetd/config.toml

# kwallet auto-unlock at login. The greetd package ships a default
# /etc/pam.d/greetd; append the two kwallet hooks once (don't rewrite the file,
# so we keep the package's version-specific stack intact).
PAM_FILE=/etc/pam.d/greetd
if [ -f "$PAM_FILE" ]; then
    if ! $SUDO grep -q 'pam_kwallet5.so' "$PAM_FILE"; then
        log "Adding kwallet PAM hooks to $PAM_FILE"
        printf '\n# arch-niri: kwallet auto-unlock at login (NetworkManager wifi secrets).\nauth     optional   pam_kwallet5.so\nsession  optional   pam_kwallet5.so auto_start\n' \
            | $SUDO tee -a "$PAM_FILE" >/dev/null
    else
        log "$PAM_FILE already has kwallet hooks; skipping"
    fi
else
    warn "$PAM_FILE not found; install greetd first. kwallet auto-unlock not configured."
fi

# Make greetd the display manager. enable (not --now) => effective next reboot.
if command -v systemctl >/dev/null 2>&1; then
    $SUDO systemctl daemon-reload
    log "Enabling greetd.service (effective next reboot)"
    $SUDO systemctl enable greetd.service
    if systemctl is-enabled sddm.service >/dev/null 2>&1; then
        log "Disabling sddm.service (replaced by greetd)"
        $SUDO systemctl disable sddm.service
    fi
    warn "greetd is now the display manager (takes effect on reboot)."
    warn "If graphical login fails, from a TTY run: sudo systemctl disable greetd"
else
    warn "systemctl unavailable; enable greetd.service manually"
fi
