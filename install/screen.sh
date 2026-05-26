#!/usr/bin/env bash
# GNU screen + its .screenrc.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs screen
stow_pkg screen
