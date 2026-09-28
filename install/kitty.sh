#!/usr/bin/env bash
# kitty terminal emulator + ~/.config/kitty/kitty.conf. Package is named "kitty"
# on every supported distro (Arch, Debian, Fedora/EPEL), so no name mapping.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool kitty
stow_pkg kitty
