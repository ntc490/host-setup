#!/usr/bin/env bash
# tig (ncurses git UI) + its .tigrc. (Package also in op-shell; see tmux.sh.)
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool tig
stow_pkg tig
