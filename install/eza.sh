#!/usr/bin/env bash
# eza: modern ls replacement (the .zshrc ls/l/la/ll/lt aliases use it).
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs eza
