#!/usr/bin/env bash
# discord: chat app, official package (Arch's `extra` repo). GUI app — run it
# explicitly (it's NOT in the default ALL list).
#
# Heads-up: Discord force-pushes mandatory updates, so when the Arch package lags
# Discord's server-required version you'll hit an "Update Required" screen until
# the package catches up (a `pacman -Syu`, usually within a day). If that nags
# you, switch to the Flatpak (com.discordapp.Discord), which updates independently.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool discord
