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
#   ./setup.sh --list          # list available modules with one-line descriptions
#   ./setup.sh --help          # this usage text
#
# Package installs need root, so you'll be prompted for sudo (unless already
# root, e.g. in a container).

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/common.sh"
require_supported

# Order matters a little: zsh first (sets up the shell + oh-my-zsh that the
# z plugin and prompt expect), and dev-tools before emacs so the build toolchain
# is in place for emacs's tree-sitter compile. (emacs also installs base-devel
# itself, so a standalone `./setup.sh emacs` still builds.)
ALL=(
    git-config
    locale
    reflector   # gated: Arch only; ranks pacman mirrors early so later installs are faster
    pacman-config  # gated: Arch only; Color/ILoveCandy/VerbosePkgLists + MAKEFLAGS=-j(nproc) before AUR builds
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
    #   obsidian          markdown notes app (GUI; run explicitly: ./setup.sh obsidian)
    #   discord           chat app (GUI; run explicitly: ./setup.sh discord)
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
    fonts       # JetBrains Mono Nerd (Arch only) + Noto base/CJK/emoji (all distros via distro_pkg)
    wallpaper   # clones the personal wallpaper image collection into ~/Wallpaper (skip headless: -x wallpaper)
    less
    rsync
    tar
    gzip
    p7zip       # 7-Zip archiver; on Arch this is the official "7zip" package
    ssh-server
    ssh-agent   # gated: Arch-only (other distros leave the agent to the session)
    ufw         # host firewall: deny incoming + allow ssh/syncthing; ufw-capable distros only
    # wezterm   # not currently using it
    tldr
    yay         # gated: Arch only; AUR helper (built via makepkg, skips if already present)
    snapper     # gated: Arch + btrfs; snapper + snap-pac (creates @snapshots if absent)
    kanata      # gated: Arch only (AUR); keyboard remapper + systemd service, home-row mods
    carbon-x1   # gated: only does anything on an Arch ThinkPad X1 Carbon
    #   arch-niri    # gated Arch-only niri Wayland desktop; off by default
                     # (GUI + sets up the sddm login). Run: ./setup.sh arch-niri
)

# --- introspection: --help / --list -----------------------------------------
# Defined before parsing so both can exit fast (no prepare_repos, no sudo) on a
# pure inspection request.

print_usage() {
    cat <<'EOF'
Usage:
  ./setup.sh                  # install + configure everything (the default ALL set)
  ./setup.sh zsh emacs        # run only the named install scripts
  ./setup.sh gui/niri/awww    # group members work by path (relative to install/)
  ./setup.sh -x less -x ag    # run everything EXCEPT the named modules

Options:
  -x, --exclude <name>        skip this module (repeatable; -xless / --exclude less)
  -l, --list                  list available modules with one-line descriptions
  -h, --help                  show this help

Sudo prompts may appear unless you're already root (e.g. in a container).
EOF
}

# Each module's first non-shebang comment line is its description.
_first_desc() {
    sed -nE '/^#!/d; /^#/ { s/^#[[:space:]]?//; p; q; }' "$1" 2>/dev/null | cut -c1-78
}

list_modules() {
    local -A in_all=()
    local m f name desc rel dir prev_dir
    local fmt='  %-18s %s\n'
    for m in "${ALL[@]}"; do in_all[$m]=1; done

    echo "Default run (in order — these run on a bare \`./setup.sh\`):"
    for m in "${ALL[@]}"; do
        desc="$(_first_desc "$HERE/install/$m.sh")"
        printf "$fmt" "$m" "$desc"
    done

    echo
    echo "Available but not in the default run (run explicitly: ./setup.sh <name>):"
    for f in "$HERE/install/"*.sh; do
        name="$(basename "$f" .sh)"
        [ -n "${in_all[$name]:-}" ] && continue
        desc="$(_first_desc "$f")"
        printf "$fmt" "$name" "$desc"
    done

    echo
    echo "Group members (invoked by their group, or directly by path: ./setup.sh <path>):"
    prev_dir=""
    while IFS= read -r f; do
        rel="${f#"$HERE/install/"}"
        dir="${rel%/*}"
        name="$(basename "$f" .sh)"
        desc="$(_first_desc "$f")"
        if [[ "$dir" != "$prev_dir" ]]; then
            echo
            echo "  $dir/"
            prev_dir="$dir"
        fi
        printf '    %-18s %s\n' "$name" "$desc"
    done < <(find "$HERE/install" -mindepth 2 -name '*.sh' -type f | sort)
}

# --- arg parsing ------------------------------------------------------------
# Positional names = run only those. -x/--exclude <name> (repeatable) drops a
# module from the run. With no positional names, the base set is the full ALL
# list (a "full run"); excludes are subtracted from whichever set applies.
# --list / --help exit early without doing any setup work.
excludes=()
scripts=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--list)    list_modules; exit 0 ;;
        -h|--help)    print_usage;  exit 0 ;;
        -x|--exclude)
            shift; [[ $# -gt 0 ]] || { echo "setup.sh: --exclude needs a module name" >&2; exit 2; }
            excludes+=("$1") ;;
        -x*) excludes+=("${1#-x}") ;;        # also accept the glued form, -xless
        --)  shift; scripts+=("$@"); break ;;
        -*)  echo "setup.sh: unknown option '$1' (try --help)" >&2; exit 2 ;;
        *)   scripts+=("$1") ;;
    esac
    shift
done

log "Detected distro: $DISTRO_ID (family: $DISTRO_FAMILY)"

# No positional names -> run the full ALL list.
if [[ ${#scripts[@]} -eq 0 ]]; then
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

# --- run --------------------------------------------------------------------
# Keep sudo's credential warm for the whole run. A full run has long, sudo-quiet
# stretches (AUR compiles, emacs build) that can outlast the 15-min timestamp,
# so the next sudo re-prompts. This refresher avoids that WITHOUT changing when
# the first prompt happens: `sudo -n -v` only *extends* an already-authenticated
# session (per-tty, shared by every module subprocess) and is a silent no-op
# otherwise -- so a run that never needs root never prompts. The first real
# prompt still comes from whichever module first calls sudo. Skipped when we're
# already root (no sudo in play). The loop exits when this script does.
if [ "$(id -u)" -ne 0 ]; then
    ( while kill -0 "$$" 2>/dev/null; do sudo -n -v 2>/dev/null || true; sleep 60; done ) &
    _sudo_keepalive_pid=$!
    trap 'kill "$_sudo_keepalive_pid" 2>/dev/null || true' EXIT
fi

# Enable extra repos (EPEL/CRB on rhel) + refresh apt lists, then ensure stow
# (several scripts need it). Done after parsing so --list/--help don't trigger
# them.
prepare_repos
ensure_stow

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
