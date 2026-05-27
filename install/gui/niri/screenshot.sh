#!/usr/bin/env bash
# Screenshot tools: grim (capture) + slurp (region selection). Used by niri's
# screenshot key binds. No config files.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool grim
install_tool slurp
