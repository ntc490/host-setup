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
# z plugin and prompt expect), and dev-tools before emacs so the build toolchain
# is in place for emacs's tree-sitter compile. (emacs also installs base-devel
# itself, so a standalone `./setup.sh emacs` still builds.)
ALL=(
    git-settings
    locale
    zsh
    fastfetch
    dev-tools
    emacs
    firefox
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
    kitty
    less
    rsync
    ssh-server
    ssh-agent   # gated: Arch-only (other distros leave the agent to the session)
    # wezterm   # not currently using it
    tldr
    carbon-x1   # gated: only does anything on an Arch ThinkPad X1 Carbon
)

# Baseline packages that don't (yet) warrant their own module. Installed
# directly on a full run; cross-distro names go through install_tool. Promote
# any of these to a real module later if it needs config/service handling.
BASE_PKGS=(
    tar
    gzip
    p7zip
)

# Enable extra repos (EPEL/CRB on rhel) + refresh apt lists up front, then
# install stow which several scripts need.
prepare_repos
ensure_stow

scripts=("$@")
if [[ ${#scripts[@]} -eq 0 ]]; then
    scripts=("${ALL[@]}")
    # Full run: install the baseline packages that don't have their own module.
    log "===== base packages ====="
    for pkg in "${BASE_PKGS[@]}"; do install_tool "$pkg"; done
fi

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
