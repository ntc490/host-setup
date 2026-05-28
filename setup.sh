#!/usr/bin/env bash
# Top-level entry point: set up this machine from scratch.
#
# Supports Arch, Debian/Ubuntu, and Rocky/RHEL/Fedora. Runs every script in
# install/ in a sensible order. Each script is independently runnable and safe
# to re-run (--needed/idempotent installs, git pull --rebase, stow --restow,
# guarded shell changes).
#
# Usage:
#   ./setup.sh                 # run everything
#   ./setup.sh zsh emacs       # run only the named install scripts
#   ./setup.sh -x less -x ag   # run everything EXCEPT the named modules
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
    git-config
    locale
    reflector   # gated: Arch only; ranks pacman mirrors early so later installs are faster
    zsh
    fastfetch
    dev-tools
    emacs
    imagemagick   # image rendering for emacs (image-dired, inline images)
    #   firefox-all       package + managed config (the usual choice)
    #   firefox           package only
    #   firefox-config    managed config only (dark theme, ja UI, extensions, no pw manager)
    #   chromium-all      package + managed policy (the usual choice)
    #   chromium          package only
    #   chromium-config   managed policy only (privacy, extensions, no pw manager)
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
    ufw         # host firewall: deny incoming + allow ssh/syncthing; ufw-capable distros only
    # wezterm   # not currently using it
    tldr
    snapper     # gated: Arch + btrfs; snapper + snap-pac (creates @snapshots if absent)
    carbon-x1   # gated: only does anything on an Arch ThinkPad X1 Carbon
    #   arch-niri    # gated Arch-only niri Wayland desktop; off by default
                     # (GUI + sets up the sddm login). Run: ./setup.sh arch-niri
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

# Parse args. Positional names = run only those. -x/--exclude <name> (repeatable)
# drops a module from the run. With no positional names, the base set is the full
# ALL list (a "full run"); excludes are subtracted from whichever set applies.
excludes=()
scripts=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -x|--exclude)
            shift; [[ $# -gt 0 ]] || { echo "setup.sh: --exclude needs a module name" >&2; exit 2; }
            excludes+=("$1") ;;
        -x*) excludes+=("${1#-x}") ;;        # also accept the glued form, -xless
        --)  shift; scripts+=("$@"); break ;;
        -*)  echo "setup.sh: unknown option '$1'" >&2; exit 2 ;;
        *)   scripts+=("$1") ;;
    esac
    shift
done

# No positional names -> full run of the ALL list (+ base packages below).
full_run=0
if [[ ${#scripts[@]} -eq 0 ]]; then
    full_run=1
    scripts=("${ALL[@]}")
fi

# Typo guard: warn about excludes that don't match anything in the run set.
for ex in "${excludes[@]}"; do
    found=0
    for name in "${scripts[@]}"; do [[ "$name" == "$ex" ]] && { found=1; break; }; done
    [[ $found -eq 0 ]] && warn "exclude '$ex' isn't in the run set; ignoring (typo?)"
done

# Drop excluded modules from the run set.
if [[ ${#excludes[@]} -gt 0 ]]; then
    filtered=()
    for name in "${scripts[@]}"; do
        skip=0
        for ex in "${excludes[@]}"; do [[ "$name" == "$ex" ]] && { skip=1; break; }; done
        [[ $skip -eq 0 ]] && filtered+=("$name")
    done
    scripts=("${filtered[@]}")
fi

if [[ ${#scripts[@]} -eq 0 ]]; then
    warn "nothing to run (everything excluded?)"
fi

# Full run also installs the baseline packages that don't have their own module.
if [[ $full_run -eq 1 ]]; then
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
