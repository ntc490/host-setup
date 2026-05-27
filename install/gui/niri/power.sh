#!/usr/bin/env bash
# TLP power management. tlp itself is generic laptop power tuning, so we install
# and enable it unconditionally. The battery charge thresholds (75-80% band) and
# the systemd-rfkill mask are ThinkPad-specific, so they're gated on the machine
# actually being a ThinkPad — running arch-niri on some other Arch laptop won't
# get mis-applied charge thresholds.
#
# NOTE: this overlaps conceptually with the carbon-x1 module (also ThinkPad
# power); it lives here because it's pulled in with the niri desktop.
source "$(dirname "$0")/../../../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"

install_tool tlp

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling tlp.service"
    $SUDO systemctl enable --now tlp.service
else
    warn "systemctl unavailable; enable tlp.service manually"
fi

if host_is "ThinkPad"; then
    # Charge-threshold drop-in (not /etc/tlp.conf) so distro updates don't clash.
    install_system_file "$HERE/00-niri.conf" /etc/tlp.d/00-niri.conf
    # TLP recommends masking systemd-rfkill so TLP owns the radio state.
    if command -v systemctl >/dev/null 2>&1; then
        log "Masking systemd-rfkill (TLP owns radio state)"
        $SUDO systemctl mask systemd-rfkill.service systemd-rfkill.socket
    fi
else
    warn "power: not a ThinkPad; skipping charge thresholds + rfkill mask (tlp still installed/enabled)"
fi
