#!/usr/bin/env bash
# Japanese input via fcitx5 + Mozc, with GTK/Qt integration modules and the
# fcitx5 config. The "environment" stow package drops ~/.config/environment.d/
# im.conf (GTK_IM_MODULE/QT_IM_MODULE/XMODIFIERS=fcitx), read at session start.
# Relies on the ja_JP.UTF-8 locale from host-setup's separate `locale` module.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool fcitx5
install_tool fcitx5-mozc
install_tool fcitx5-gtk
install_tool fcitx5-qt
stow_pkg fcitx5
stow_pkg environment
