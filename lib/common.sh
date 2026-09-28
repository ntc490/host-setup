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

# host_is <substring> — true if any of this machine's DMI identity fields
# (product family/version/name, board name) contains <substring>
# (case-insensitive). Lets hardware-specific modules detect the machine they
# belong to, e.g. `host_is "X1 Carbon"` (matches product_family) or
# `host_is "X202EV"` (matches product_name/board_name where product_family is
# just "X").
host_is() {
    local want=$1 dmi
    dmi="$(cat /sys/class/dmi/id/product_family \
               /sys/class/dmi/id/product_version \
               /sys/class/dmi/id/product_name \
               /sys/class/dmi/id/board_name 2>/dev/null || true)"
    case "${dmi,,}" in *"${want,,}"*) return 0 ;; *) return 1 ;; esac
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
        firefox)
            [ "$DISTRO_FAMILY" = debian ] && echo "firefox-esr" || echo "firefox" ;;
        imagemagick)
            [ "$DISTRO_FAMILY" = rhel ] && echo "ImageMagick" || echo "imagemagick" ;;
        p7zip)
            # Arch dropped p7zip from its repos (2023) for the official "7zip"
            # port; Debian splits the full CLI into p7zip-full; RHEL/EPEL keeps p7zip.
            case "$DISTRO_FAMILY" in
                arch)   echo "7zip" ;;
                debian) echo "p7zip-full" ;;
                *)      echo "p7zip" ;;
            esac ;;
        openssh)
            [ "$DISTRO_FAMILY" = arch ] && echo "openssh" || echo "openssh-server" ;;
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
        noto-fonts)
            case "$DISTRO_FAMILY" in
                arch)   echo "noto-fonts" ;;
                debian) echo "fonts-noto-core" ;;
                rhel)   echo "google-noto-sans-fonts" ;;
            esac ;;
        noto-fonts-cjk)
            case "$DISTRO_FAMILY" in
                arch)   echo "noto-fonts-cjk" ;;
                debian) echo "fonts-noto-cjk" ;;
                rhel)   echo "google-noto-sans-cjk-ttc-fonts" ;;   # appstream
            esac ;;
        noto-fonts-emoji)
            case "$DISTRO_FAMILY" in
                arch)   echo "noto-fonts-emoji" ;;
                debian) echo "fonts-noto-color-emoji" ;;
                rhel)   echo "google-noto-emoji-color-fonts" ;;
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

# aur_install <pkg> — build and install an AUR package via makepkg. Arch only,
# and idempotent (skips if already installed). makepkg refuses to run as root,
# so when we're root (e.g. in a container) this warns and skips rather than
# failing. The makepkg -si step will itself sudo for the final pacman -U.
aur_install() {
    local pkg=$1 build
    if [ "$DISTRO_FAMILY" != arch ]; then
        warn "$pkg: AUR install is Arch-only; skipping on $DISTRO_ID"
        return 0
    fi
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        log "$pkg already installed"
        return 0
    fi
    if [ "$(id -u)" -eq 0 ]; then
        warn "$pkg: makepkg can't run as root; install it from the AUR as a normal user, then re-run"
        return 0
    fi
    install_pkgs git        # needed to clone the AUR repo
    install_tool base-devel # makepkg needs the toolchain
    build="$(mktemp -d)"
    log "Building $pkg from the AUR in $build"
    git clone "https://aur.archlinux.org/${pkg}.git" "$build/$pkg"
    ( cd "$build/$pkg" && makepkg -si --noconfirm )
    rm -rf "$build"
}

# ---------------------------------------------------------------------------
# git clone / update
# ---------------------------------------------------------------------------
# clone_or_update <repo-url> <dest> [--recursive]
# First run clones; later runs pull --rebase (and refresh submodules if recursive).
clone_or_update() {
    local repo=$1 dest=$2 recursive=${3:-}
    # Each git step propagates failure via `|| return 1` — otherwise the
    # trailing `if [[ $recursive ]]` test would be the function's last command
    # and mask a failed pull/clone (returning 0 on a non-recursive call).
    if [[ -d "$dest/.git" ]]; then
        log "Updating $dest (git pull --rebase)"
        git -C "$dest" pull --rebase || return 1
        if [[ "$recursive" == "--recursive" ]]; then
            git -C "$dest" submodule update --init --recursive || return 1
        fi
    else
        log "Cloning $repo -> $dest"
        if [[ "$recursive" == "--recursive" ]]; then
            git clone --recursive "$repo" "$dest" || return 1
        else
            git clone "$repo" "$dest" || return 1
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
#
# Guarded: before touching a target, every path component under $HOME is
# checked. If one is a symlink managed by *another* repo (i.e. it doesn't
# resolve back into our own dotfiles), we refuse rather than write through it —
# following a foreign dir-symlink once clobbered a sibling repo's config. When a
# component is our *own* stow symlink, the file is already managed, so we skip
# the backup mv (which would otherwise rename our repo file through the link).
stow_pkg() {
    local pkg=$1 f rel target
    ensure_stow
    local pkgdir="$DOTFILES_DIR/$pkg" own
    own="$(readlink -f "$DOTFILES_DIR")"

    while IFS= read -r -d '' f; do
        rel=${f#"$pkgdir/"}
        target="$HOME/$rel"

        # Walk each path component of the target, looking for symlinks.
        local probe="$HOME" comp dest had_symlink=0
        while IFS= read -r comp; do
            [ -n "$comp" ] || continue
            probe="$probe/$comp"
            if [ -L "$probe" ]; then
                had_symlink=1
                dest="$(readlink -f "$probe" 2>/dev/null || true)"
                case "${dest}/" in
                    "$own/"*) : ;;   # our own stow symlink — fine, leave it
                    *)
                        warn "stow $pkg: '$probe' is a symlink not managed by this repo (-> ${dest:-unresolved})."
                        warn "Refusing to stow '$pkg' so we don't write through it; remove/relocate that link, then re-run."
                        return 1 ;;
                esac
            fi
        done < <(printf '%s\n' "$rel" | tr '/' '\n')

        # Only back up a real conflicting file that sits in real directories. If
        # a symlink is in the path it's ours (foreign ones returned above), so
        # the file is already managed and must not be mv'd through the link.
        if [ "$had_symlink" -eq 0 ] && [ -e "$target" ] && [ ! -L "$target" ]; then
            log "Backing up existing $target -> ${target}.bak.$(date +%s)"
            mv "$target" "${target}.bak.$(date +%s)"
        fi
    done < <(find "$pkgdir" -type f -print0)

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

# install_system_file <src> <dest> [mode] — copy a file into a root-owned system
# path (e.g. under /etc), via sudo, only if it changed. Creates parent dirs.
# Default mode 0644. Use this for system config/units, not $HOME dotfiles.
install_system_file() {
    local src=$1 dest=$2 mode=${3:-0644}
    if [[ -e "$dest" ]] && cmp -s "$src" "$dest"; then
        log "$dest already up to date"
        return 0
    fi
    log "Installing $dest"
    $SUDO install -D -m "$mode" -o root -g root "$src" "$dest"
}
