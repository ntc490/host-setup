#!/usr/bin/env bash
# Shared helpers for the host-setup install scripts.
# Source this from any install/*.sh; it is safe to source more than once.

set -euo pipefail

# Repo layout (resolved relative to this file, so scripts work from anywhere).
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$LIB_DIR/.." && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
VENDOR_DIR="$REPO_DIR/vendor"

log()  { printf '==> %s\n' "$*"; }
warn() { printf '==> WARNING: %s\n' "$*" >&2; }

# Bail early if we're not on Arch — these scripts target pacman only.
require_arch() {
    if [[ "$(uname -s)" != "Linux" ]] || ! command -v pacman >/dev/null 2>&1; then
        echo "host-setup targets Arch Linux (pacman). Aborting." >&2
        exit 1
    fi
}

# install_pkgs pkg [pkg ...]
# pacman -S --needed skips anything already installed, so this is idempotent.
install_pkgs() {
    log "pacman -S --needed ${*}"
    sudo pacman -S --needed --noconfirm "$@"
}

# clone_or_update <repo-url> <dest> [--recursive]
# First run clones; later runs pull --rebase (and refresh submodules if recursive).
clone_or_update() {
    local repo=$1 dest=$2 recursive=${3:-}
    if [[ -d "$dest/.git" ]]; then
        log "Updating $dest (git pull --rebase)"
        git -C "$dest" pull --rebase
        [[ "$recursive" == "--recursive" ]] && \
            git -C "$dest" submodule update --init --recursive
    else
        log "Cloning $repo -> $dest"
        if [[ "$recursive" == "--recursive" ]]; then
            git clone --recursive "$repo" "$dest"
        else
            git clone "$repo" "$dest"
        fi
    fi
}

ensure_stow() {
    command -v stow >/dev/null 2>&1 || install_pkgs stow
}

# stow_pkg <package>
# Symlinks dotfiles/<package>/* into $HOME. Any pre-existing *real* file (not a
# symlink) that would conflict is backed up first, so this is safe to re-run on
# a machine that already has hand-placed configs.
stow_pkg() {
    local pkg=$1 f rel target
    ensure_stow
    while IFS= read -r -d '' f; do
        rel=${f#"$DOTFILES_DIR/$pkg/"}
        target="$HOME/$rel"
        if [[ -e "$target" && ! -L "$target" ]]; then
            log "Backing up existing $target -> ${target}.bak.$(date +%s)"
            mv "$target" "${target}.bak.$(date +%s)"
        fi
    done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
    log "stow $pkg"
    stow -d "$DOTFILES_DIR" -t "$HOME" -v --restow "$pkg"
}

# install_bin <vendor-file> <dest-path>
# Copies a vendored binary/script into place, executable, only if changed.
install_bin() {
    local src="$VENDOR_DIR/$1" dest=$2
    mkdir -p "$(dirname "$dest")"
    if [[ ! -e "$dest" ]] || ! cmp -s "$src" "$dest"; then
        log "Installing $dest"
        install -m 0755 "$src" "$dest"
    fi
}
