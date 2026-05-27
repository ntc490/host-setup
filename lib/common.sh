#!/usr/bin/env bash
# Shared helpers for the host-setup install scripts.
# Source this from any install/*.sh; it is safe to source more than once.
#
# Supports Arch (pacman), Debian/Ubuntu (apt), and Rocky/RHEL/Fedora (dnf).

set -euo pipefail

# Repo layout (resolved relative to this file, so scripts work from anywhere).
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$LIB_DIR/.." && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
VENDOR_DIR="$REPO_DIR/vendor"

log()  { printf '==> %s\n' "$*"; }
warn() { printf '==> WARNING: %s\n' "$*" >&2; }

# Run privileged commands via sudo, unless we're already root (e.g. in a
# container, where sudo may not even be installed).
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

# ---------------------------------------------------------------------------
# Distro detection
# ---------------------------------------------------------------------------
# DISTRO_ID is the raw os-release ID (arch, debian, ubuntu, rocky, ...).
# DISTRO_FAMILY collapses that to a package-manager family: arch|debian|rhel.
DISTRO_ID="$(. /etc/os-release 2>/dev/null && echo "${ID:-unknown}")"
_distro_like="$(. /etc/os-release 2>/dev/null && echo "${ID_LIKE:-}")"
DISTRO_FAMILY=""
case " $DISTRO_ID $_distro_like " in
    *" arch "*|*" archlinux "*)            DISTRO_FAMILY="arch" ;;
    *" debian "*|*" ubuntu "*)             DISTRO_FAMILY="debian" ;;
    *" rhel "*|*" fedora "*|*" centos "*)  DISTRO_FAMILY="rhel" ;;
esac

require_supported() {
    if [ -z "$DISTRO_FAMILY" ]; then
        echo "Unsupported distro (ID=$DISTRO_ID). Supported: arch, debian/ubuntu, rhel/rocky/fedora." >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Repos: refresh apt lists / enable EPEL+CRB on rhel. Marker files keep this
# to once per setup.sh run even though each install script is its own process.
# ---------------------------------------------------------------------------
_apt_update() {
    local marker=/tmp/.host-setup-apt-updated
    [ -f "$marker" ] && return 0
    log "apt-get update"
    $SUDO apt-get update -qq
    touch "$marker"
}

enable_extra_repos() {
    [ "$DISTRO_FAMILY" = "rhel" ] || return 0
    local marker=/tmp/.host-setup-epel
    [ -f "$marker" ] && return 0
    log "Enabling EPEL + CRB"
    $SUDO dnf install -y epel-release dnf-plugins-core
    $SUDO dnf config-manager --set-enabled crb 2>/dev/null \
        || $SUDO dnf config-manager --set-enabled powertools 2>/dev/null \
        || warn "could not enable CRB/PowerTools (some packages may be missing)"
    touch "$marker"
}

# Make repos queryable/installable. Cheap to call repeatedly (marker-guarded).
prepare_repos() {
    enable_extra_repos
    [ "$DISTRO_FAMILY" = "debian" ] && _apt_update
    return 0
}

# ---------------------------------------------------------------------------
# Package install
# ---------------------------------------------------------------------------
# install_pkgs pkg [pkg ...] — install given (already distro-correct) packages.
# Idempotent: pacman --needed / apt / dnf all skip what's already present.
install_pkgs() {
    [ "$#" -eq 0 ] && return 0
    case "$DISTRO_FAMILY" in
        arch)
            log "pacman -S --needed $*"
            $SUDO pacman -S --needed --noconfirm "$@" ;;
        debian)
            _apt_update
            log "apt-get install $*"
            # Use `env` to set DEBIAN_FRONTEND: a bare VAR=val prefix breaks when
            # $SUDO is empty (bash then treats the assignment as the command).
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
        rhel)
            log "dnf install $*"
            $SUDO dnf install -y "$@" ;;
        *)
            warn "unknown distro family; cannot install: $*"; return 1 ;;
    esac
}

# pkg_in_repo <name> — true if the package is installable from configured repos.
pkg_in_repo() {
    case "$DISTRO_FAMILY" in
        arch)   pacman -Si "$1" >/dev/null 2>&1 || pacman -Sg "$1" >/dev/null 2>&1 ;;
        debian) apt-cache show "$1" 2>/dev/null | grep -q '^Package:' ;;
        rhel)   $SUDO dnf -q info "$1" >/dev/null 2>&1 ;;
    esac
}

# distro_pkg <logical> — map a logical tool name to the package name(s) for the
# current distro. Most tools share a name everywhere; only the ones that differ
# need a case. Returns possibly multiple space-separated names.
distro_pkg() {
    case "$1" in
        emacs)
            [ "$DISTRO_FAMILY" = arch ] && echo "emacs-wayland" || echo "emacs" ;;
        ag)
            [ "$DISTRO_FAMILY" = debian ] && echo "silversearcher-ag" || echo "the_silver_searcher" ;;
        fd)
            [ "$DISTRO_FAMILY" = arch ] && echo "fd" || echo "fd-find" ;;
        base-devel)
            case "$DISTRO_FAMILY" in
                arch)   echo "base-devel" ;;
                debian) echo "build-essential" ;;
                rhel)   echo "gcc gcc-c++ make automake autoconf libtool pkgconf-pkg-config" ;;
            esac ;;
        clang)
            case "$DISTRO_FAMILY" in
                arch)   echo "clang" ;;
                debian) echo "clang clang-format clang-tidy" ;;
                rhel)   echo "clang clang-tools-extra" ;;
            esac ;;
        *) echo "$1" ;;
    esac
}

# install_tool <logical> — resolve the package name(s) for this distro, install
# the ones that exist in the repos, and skip+warn for any that don't. This is
# what install scripts should call.
install_tool() {
    require_supported
    prepare_repos
    local logical=$1 names p avail=() missing=()
    names="$(distro_pkg "$logical")"
    if [ -z "$names" ]; then
        warn "$logical: no package mapping for $DISTRO_ID; skipping"
        return 0
    fi
    for p in $names; do
        if pkg_in_repo "$p"; then avail+=("$p"); else missing+=("$p"); fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        warn "$logical: not available on $DISTRO_ID: ${missing[*]}"
    fi
    if [ "${#avail[@]}" -gt 0 ]; then
        install_pkgs "${avail[@]}"
    else
        warn "$logical: nothing to install on $DISTRO_ID; skipping"
    fi
}

# ---------------------------------------------------------------------------
# git clone / update
# ---------------------------------------------------------------------------
# clone_or_update <repo-url> <dest> [--recursive]
# First run clones; later runs pull --rebase (and refresh submodules if recursive).
clone_or_update() {
    local repo=$1 dest=$2 recursive=${3:-}
    if [[ -d "$dest/.git" ]]; then
        log "Updating $dest (git pull --rebase)"
        git -C "$dest" pull --rebase
        if [[ "$recursive" == "--recursive" ]]; then
            git -C "$dest" submodule update --init --recursive
        fi
    else
        log "Cloning $repo -> $dest"
        if [[ "$recursive" == "--recursive" ]]; then
            git clone --recursive "$repo" "$dest"
        else
            git clone "$repo" "$dest"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Dotfiles (stow) and vendored binaries
# ---------------------------------------------------------------------------
ensure_stow() {
    command -v stow >/dev/null 2>&1 && return 0
    prepare_repos
    install_pkgs stow
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
