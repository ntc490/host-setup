#!/usr/bin/env bash
# WezTerm + ~/.wezterm.lua and the wconf.py opacity helper (-> ~/.local/bin).
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs wezterm
stow_pkg wezterm
install_bin wconf.py "$HOME/.local/bin/wconf.py"
