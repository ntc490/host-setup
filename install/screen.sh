#!/usr/bin/env bash
# GNU screen + its .screenrc.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool screen
stow_pkg screen
