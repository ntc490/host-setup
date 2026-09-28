#!/usr/bin/env bash
# Lenovo ThinkPad X1 Carbon specific setup. A GROUP script (like dev-tools):
# it gates on the hardware + distro, then runs every member in install/carbon-x1/.
#
# Gated so it's safe in the default ALL run: on any other machine or distro it
# cleanly warns and exits 0 rather than doing anything.
source "$(dirname "$0")/../lib/common.sh"

if [ "$DISTRO_FAMILY" != "arch" ]; then
    warn "carbon-x1: Arch-only module; skipping on $DISTRO_ID"
    exit 0
fi
if ! host_is "X1 Carbon"; then
    warn "carbon-x1: not a ThinkPad X1 Carbon; skipping"
    exit 0
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
for member in "$HERE/carbon-x1/"*.sh; do
    [ -e "$member" ] || continue   # no members yet -> nothing to do
    log "----- carbon-x1/$(basename "$member") -----"
    "$member"
done
