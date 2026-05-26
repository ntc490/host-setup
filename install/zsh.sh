#!/usr/bin/env bash
# zsh + oh-my-zsh + plugins, the .zshrc dotfile, and make zsh the login shell.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool zsh
install_tool fastfetch   # not in every distro's repos; skipped with a warning if absent

ZSH_DIR="$HOME/.oh-my-zsh"
clone_or_update https://github.com/robbyrussell/oh-my-zsh.git "$ZSH_DIR"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_DIR/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_DIR/plugins/zsh-syntax-highlighting"

stow_pkg zsh

# Switch the login shell to zsh only if it isn't already (avoids a needless
# sudo/password prompt on re-runs). Resolve the zsh path rather than hard-coding
# it, since it differs across distros.
zsh_path="$(command -v zsh || true)"
if [[ -z "$zsh_path" ]]; then
    warn "zsh not found on PATH; skipping login-shell change"
elif [[ "${SHELL:-}" == *"/zsh" ]]; then
    log "Login shell already zsh"
else
    log "Changing login shell to $zsh_path"
    $SUDO chsh -s "$zsh_path" "$USER"
fi
