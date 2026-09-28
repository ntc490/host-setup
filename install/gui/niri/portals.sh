#!/usr/bin/env bash
# xdg-desktop-portal backends: the gtk portal (file pickers, settings) and the
# gnome portal (screen sharing / screencast, global shortcuts) that screenshare
# and Wayland apps expect. No config — they're D-Bus activated.
source "$(dirname "$0")/../../../lib/common.sh"

install_tool xdg-desktop-portal-gtk
install_tool xdg-desktop-portal-gnome
