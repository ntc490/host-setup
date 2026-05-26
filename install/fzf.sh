#!/usr/bin/env bash
# fzf: command-line fuzzy finder. (The .zshrc sources ~/.fzf.zsh if present;
# the Arch package ships its shell bindings under /usr/share/fzf/ instead.)
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs fzf
