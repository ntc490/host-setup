#!/usr/bin/env bash
# Desktop fonts: Noto (base + CJK for Japanese + emoji) and the JetBrains Mono
# Nerd Font used by waybar/kitty/terminal. No config.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool noto-fonts
install_tool noto-fonts-cjk
install_tool noto-fonts-emoji
install_tool ttf-jetbrains-mono-nerd
