#!/usr/bin/env bash
# Run setup.sh inside throwaway podman containers to test it across distros
# without touching the host. Each run executes setup.sh TWICE to verify the
# scripts are idempotent (re-running must also succeed cleanly).
#
# Usage:
#   test/run-in-container.sh <arch|debian|rocky|all> [script ...]
#
#   # default: a CLI-safe subset (skips emacs's make step and the GUI wezterm)
#   test/run-in-container.sh debian
#
#   # run specific scripts
#   test/run-in-container.sh rocky tmux tig dev-tools
#
#   # run absolutely everything setup.sh knows about
#   test/run-in-container.sh all full

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

# Distro -> base image.
image_for() {
    case "$1" in
        arch)   echo "docker.io/library/archlinux:latest" ;;
        debian) echo "docker.io/library/debian:12" ;;
        rocky)  echo "docker.io/rockylinux/rockylinux:9" ;;
        *)      return 1 ;;
    esac
}

# CLI-safe default subset: exercises package install, name mapping, stow, the
# dev-tools group, and skip+warn — without the heavy emacs `make` or GUI wezterm.
DEFAULT_SCRIPTS="zsh fastfetch ag fd screen tmux tig eza bat fzf htop btop dev-tools tldr git-settings"

usage() { echo "Usage: $0 <arch|debian|rocky|all> [script ...|full]" >&2; exit 1; }
[ $# -ge 1 ] || usage
target=$1; shift || true

# "full" => let setup.sh run its entire ALL list; otherwise use given args or
# the default subset.
if [ "${1:-}" = "full" ]; then
    scripts=""
elif [ $# -gt 0 ]; then
    scripts="$*"
else
    scripts="$DEFAULT_SCRIPTS"
fi

# The bootstrap installs git (needed for the oh-my-zsh / emacs clones) and
# refreshes package metadata, then runs setup.sh twice from a writable copy.
CONTAINER_SCRIPT='
set -e
if command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm git
elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y git ca-certificates >/dev/null
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y git >/dev/null
fi
cp -a /src /work && cd /work
echo "===== RUN 1 ====="
./setup.sh $SCRIPTS
echo "===== RUN 2 (idempotency) ====="
./setup.sh $SCRIPTS
echo "===== CONTAINER OK ====="
'

run_one() {
    local distro=$1 image
    image="$(image_for "$distro")" || { echo "unknown distro: $distro" >&2; return 2; }
    echo
    echo "##################################################################"
    echo "##  $distro  ($image)"
    echo "##################################################################"
    podman run --rm \
        -v "$REPO":/src:ro \
        -e SCRIPTS="$scripts" \
        "$image" /bin/sh -c "$CONTAINER_SCRIPT"
}

declare -a results=()
status=0
case "$target" in
    all)
        for d in arch debian rocky; do
            if run_one "$d"; then results+=("PASS $d"); else results+=("FAIL $d"); status=1; fi
        done ;;
    arch|debian|rocky)
        if run_one "$target"; then results+=("PASS $target"); else results+=("FAIL $target"); status=1; fi ;;
    *) usage ;;
esac

echo
echo "==================== SUMMARY ===================="
printf '  %s\n' "${results[@]}"
exit $status
