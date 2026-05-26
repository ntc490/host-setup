#!/usr/bin/env bash
# tmux + its .tmux.conf. (The package is also in op-shell; --needed makes the
# duplicate install a no-op, and this keeps the script runnable on its own.)
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs tmux
stow_pkg tmux
