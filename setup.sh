#!/usr/bin/env bash
# Top-level entry point: set up this Arch machine from scratch.
#
# Runs every script in install/ in a sensible order. Each script is
# independently runnable and safe to re-run (pacman -S --needed, git pull
# --rebase, stow --restow, guarded shell/group changes).
#
# Usage:
#   ./setup.sh              # run everything
#   ./setup.sh zsh emacs    # run only the named install scripts
#
# stow needs sudo for package installs, so you'll be prompted for your
# password once pacman first runs.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/common.sh"
require_arch

# Order matters a little: zsh first (sets up the shell + oh-my-zsh that the
# z plugin and prompt expect), then the rest.
ALL=(
    zsh
    emacs
    ag
    fd
    screen
    tmux
    tig
    eza
    bat
    fzf
    htop
    btop
    wezterm
    dev-tools
    tldr
)

# stow is needed by several scripts; install it up front.
ensure_stow

scripts=("$@")
[[ ${#scripts[@]} -eq 0 ]] && scripts=("${ALL[@]}")

for name in "${scripts[@]}"; do
    script="$HERE/install/${name}.sh"
    if [[ ! -x "$script" ]]; then
        warn "No such install script: $name (skipping)"
        continue
    fi
    log "===== $name ====="
    "$script"
done

log "setup.sh complete."
