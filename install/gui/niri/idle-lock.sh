#!/usr/bin/env bash
# Screen lock + idle management: hyprlock (the lock screen) and hypridle (the
# idle daemon that drives lock -> monitor-off -> suspend). Both configs live in
# the single "hypr" stow package (~/.config/hypr/{hyprlock,hypridle}.conf).
source "$(dirname "$0")/../../../lib/common.sh"

install_tool hypridle
install_tool hyprlock
stow_pkg hypr
