#!/usr/bin/env bash
# fuzzel application launcher + config. Bound to Mod+Space in niri, and also used
# as the dmenu for the Mod+Y clipboard-history picker.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool fuzzel
stow_pkg fuzzel
