#!/usr/bin/env bash
# obsidian: markdown notes app. The official package is in Arch's `extra` repo;
# elsewhere it ships as Flatpak/AppImage, so install_tool skips+warns there.
# GUI app — run it explicitly (it's not in the default ALL list).
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool obsidian
