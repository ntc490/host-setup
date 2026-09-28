#!/usr/bin/env bash
# Power management for the X1 Carbon: TLP with a ThinkPad battery charge band
# (75-80%) to slow wear. The charge-threshold drop-in and the systemd-rfkill
# mask are ThinkPad features, which is why this lives in the carbon-x1 group
# rather than a generic module. (Run via the carbon-x1 group, which has already
# gated on Arch + X1 Carbon.)
source "$(dirname "$0")/../../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"

install_tool tlp

# Charge thresholds via a drop-in (not /etc/tlp.conf) so distro updates don't
# clash. For a long trip, temporarily allow a full charge: sudo tlp fullcharge BAT0
install_system_file "$HERE/tlp.conf" /etc/tlp.d/00-carbon-x1.conf

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling tlp.service"
    $SUDO systemctl enable --now tlp.service
    # TLP recommends masking systemd-rfkill so TLP owns the radio state.
    log "Masking systemd-rfkill (TLP owns radio state)"
    $SUDO systemctl mask systemd-rfkill.service systemd-rfkill.socket
else
    warn "systemctl unavailable; enable tlp.service + mask systemd-rfkill manually"
fi
