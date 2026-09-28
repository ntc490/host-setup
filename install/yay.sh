#!/usr/bin/env bash
# yay: AUR helper, for convenient interactive AUR use. Built from the AUR via
# makepkg (aur_install handles the clone + build, skips if already present, and
# is Arch-only / can't run as root). The repo's own AUR installs use aur_install
# directly, so yay isn't a dependency of host-setup — it's just for you.
source "$(dirname "$0")/../lib/common.sh"

aur_install yay
