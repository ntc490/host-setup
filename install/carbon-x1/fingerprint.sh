#!/usr/bin/env bash
# Fingerprint reader for the X1 Carbon: fprintd (+ libfprint), with fingerprint
# auth added to sudo's PAM stack as a `sufficient` rule — a successful swipe
# authenticates, anything else falls through to the password, so it can't lock
# you out. Enrollment needs a physical swipe, so it's a manual step (printed at
# the end), not something this script can do. (Run via the carbon-x1 group:
# Arch + X1 Carbon already gated.)
#
# The hyprlock lock screen is deliberately NOT wired here via PAM: hyprlock only
# runs its PAM stack after you submit the password field, so pam_fprintd there
# means "type something, THEN swipe" — the wrong UX. hyprlock instead has a
# native fprintd D-Bus backend enabled in dotfiles/hypr/hyprlock.conf, which
# verifies in parallel for true swipe-to-unlock. sudo has no such backend, so
# PAM is the right (and only) mechanism there.
#
# This Carbon's reader is Synaptics 06cb:00bd (Prometheus "MIS" = match-in-sensor:
# templates live on the sensor, not on disk — so enrollment is per-install, you
# re-enroll after a wipe). Current libfprint has a `synaptics` driver that should
# drive it out of the box. If `fprintd-enroll` instead reports "No devices
# available", this firmware needs the reverse-engineered python-validity /
# open-fprintd (AUR) stack instead — deliberately left out here.
source "$(dirname "$0")/../../lib/common.sh"

install_tool fprintd   # pulls in libfprint, the reader driver library

# enable_fprint_pam <pam-file> — insert pam_fprintd as the FIRST `auth` rule,
# idempotently. `sufficient` means a swipe short-circuits to success while a
# miss falls through to the existing rules, so this never removes the password
# path. Inserting before the first `auth` line makes the swipe the first prompt.
enable_fprint_pam() {
    local file=$1
    if [ ! -f "$file" ]; then
        warn "fprint: $file not present; skipping fingerprint auth there"
        return 0
    fi
    if grep -q 'pam_fprintd.so' "$file"; then
        log "fprint: $(basename "$file") already wired for fingerprint"
        return 0
    fi
    log "Enabling fingerprint auth in $file"
    $SUDO sed -i '0,/^auth/s//auth\t\tsufficient\tpam_fprintd.so\n&/' "$file"
}

enable_fprint_pam /etc/pam.d/sudo

# (hyprlock fingerprint is NOT wired here — see the header note; it's enabled in
# dotfiles/hypr/hyprlock.conf as a native fprintd backend.)

# fprintd is D-Bus activated, so there's no service to enable.
#
# Enrollment is polkit-gated (net.reactivated.fprint.device.enroll =
# auth_self_keep), so it needs a polkit agent running to prompt for your
# password — the arch-niri group's polkit member provides one. Without a
# graphical session, use the bundled text agent: run `pkttyagent &` first.
# And enroll as YOUR user, NOT via sudo: `sudo fprintd-enroll` enrols root,
# whose prints sudo/hyprlock never check (they authenticate as you).
log "fprintd installed and PAM wired for sudo (hyprlock uses its own fprintd backend)."
log "Enroll a finger (manual swipe, NOT via sudo):   fprintd-enroll"
log "Test it:   fprintd-verify   then:   sudo -k && sudo true"
