#!/usr/bin/env bash
# Top-level entry point: set up this machine from scratch.
#
# Supports Arch, Debian/Ubuntu, and Rocky/RHEL/Fedora. Runs every script in
# install/ in a sensible order. Each script is independently runnable and safe
# to re-run (--needed/idempotent installs, git pull --rebase, stow --restow,
# guarded shell changes).
#
# Usage:
#   ./setup.sh              # run everything
#   ./setup.sh zsh emacs    # run only the named install scripts
#
# Package installs need root, so you'll be prompted for sudo (unless already
# root, e.g. in a container).

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/common.sh"
require_supported
log "Detected distro: $DISTRO_ID (family: $DISTRO_FAMILY)"

# Order matters a little: zsh first (sets up the shell + oh-my-zsh that the
# z plugin and prompt expect), then the rest.
ALL=(
    git-settings
    zsh
    fastfetch
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
    # wezterm   # not currently using it
    dev-tools
    tldr
)

# Enable extra repos (EPEL/CRB on rhel) + refresh apt lists up front, then
# install stow which several scripts need.
prepare_repos
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
