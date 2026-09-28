#!/usr/bin/env bash
# zsh + oh-my-zsh + plugins, the .zshrc dotfile, and make zsh the login shell.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool zsh

ZSH_DIR="$HOME/.oh-my-zsh"
clone_or_update https://github.com/robbyrussell/oh-my-zsh.git "$ZSH_DIR"

# Third-party plugins belong in $ZSH_CUSTOM/plugins, not oh-my-zsh's bundled
# plugins/ dir (where they show up as untracked files in its checkout). Remove
# clones left there by older versions of this module.
ZSH_CUSTOM_DIR="$ZSH_DIR/custom"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ -d "$ZSH_DIR/plugins/$plugin/.git" ]]; then
        log "Removing old $plugin clone from $ZSH_DIR/plugins"
        rm -rf "$ZSH_DIR/plugins/$plugin"
    fi
done
clone_or_update https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"

stow_pkg zsh

# Switch the login shell to zsh only if it isn't already (avoids a needless
# sudo/password prompt on re-runs). Resolve the zsh path rather than hard-coding
# it, since it differs across distros.
zsh_path="$(command -v zsh || true)"
if [[ -z "$zsh_path" ]]; then
    warn "zsh not found on PATH; skipping login-shell change"
elif [[ "${SHELL:-}" == *"/zsh" ]]; then
    log "Login shell already zsh"
elif ! command -v chsh >/dev/null 2>&1; then
    warn "chsh not available; skipping login-shell change (set it manually)"
else
    log "Changing login shell to $zsh_path"
    $SUDO chsh -s "$zsh_path" "$(id -un)"
fi
