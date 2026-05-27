#!/usr/bin/env bash
# mako notification daemon + config. niri spawns it at startup; Mod+Shift+N /
# Mod+Ctrl+N dismiss notifications via makoctl.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool mako
stow_pkg mako
