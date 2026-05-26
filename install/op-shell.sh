#!/usr/bin/env bash
# "Everyday" shell tools bundle. tmux/tig configs are stowed by their own
# scripts; here we just install the package set.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs tmux tig eza bat fzf htop btop
