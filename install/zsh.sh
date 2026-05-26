#!/usr/bin/env bash
# zsh + oh-my-zsh + plugins, the .zshrc dotfile, and make zsh the login shell.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs zsh fastfetch

ZSH_DIR="$HOME/.oh-my-zsh"
clone_or_update https://github.com/robbyrussell/oh-my-zsh.git "$ZSH_DIR"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_DIR/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_DIR/plugins/zsh-syntax-highlighting"

stow_pkg zsh

# Switch the login shell to zsh only if it isn't already (avoids a needless
# sudo/password prompt on re-runs).
if [[ "$SHELL" != */zsh ]]; then
    log "Changing login shell to /usr/bin/zsh"
    chsh -s /usr/bin/zsh "$USER"
else
    log "Login shell already zsh"
fi
