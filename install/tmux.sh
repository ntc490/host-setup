#!/usr/bin/env bash
# tmux + its .tmux.conf. (The package is also in op-shell; --needed makes the
# duplicate install a no-op, and this keeps the script runnable on its own.)
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool tmux
stow_pkg tmux
