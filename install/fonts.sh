#!/usr/bin/env bash
# Fonts for terminal + desktop use. These don't compete — fontconfig layers them
# (your monospace renders code/icons; Noto picks up Japanese, emoji, and exotic-
# script fallback):
#   * ttf-jetbrains-mono-nerd — your terminal/editor monospace, patched with the
#     icon glyphs used by eza/starship/kitty/waybar. Only Arch packages the
#     Nerd-patched variant; on other distros install_tool warns + skips here
#     (install the .ttf by hand on a non-Arch workstation if you ever need it —
#     headless SSH targets don't, since terminal rendering happens client-side).
#   * Noto base + CJK + emoji — Japanese rendering, color emoji, and the "no
#     tofu" Latin/Cyrillic/etc. fallback. In every distro's repos under different
#     names; handled by the distro_pkg mapping in lib/common.sh.
#
# Skip on a headless box where you don't want ~hundreds of MB of CJK:
#   ./setup.sh -x fonts
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool noto-fonts
install_tool noto-fonts-cjk
install_tool noto-fonts-emoji
install_tool ttf-jetbrains-mono-nerd
