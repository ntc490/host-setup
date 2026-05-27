#!/usr/bin/env bash
# Desktop GTK preferences for the niri session:
#   1. Dark color scheme — the freedesktop "color-scheme" preference is the
#      single source of truth portal-aware apps read to choose light/dark (GTK
#      apps, Chromium, and Firefox all follow it via xdg-desktop-portal). Set via
#      gsettings; persisted in dconf, so it sticks across logins.
#   2. Emacs key theme — Emacs/readline text-editing keys (C-a/C-e/C-k/...) in
#      GTK text widgets, via a stowed gtk-3.0/settings.ini (+ .gtkrc-2.0). The key
#      theme isn't portal/gsettings-reachable on a bare niri session, hence a
#      file. GTK2/GTK3 apps honor it — including Firefox (its page inputs AND the
#      address bar). Chromium does NOT (own input handling); GTK4 dropped key themes.
# (Run via the arch-niri group, which has already gated on Arch.)
source "$(dirname "$0")/../../../lib/common.sh"

# Provides the org.gnome.desktop.interface schema (color-scheme key); pulls glib2,
# which provides the gsettings tool.
install_tool gsettings-desktop-schemas

if command -v gsettings >/dev/null 2>&1 \
   && gsettings get org.gnome.desktop.interface color-scheme >/dev/null 2>&1; then
    log "Setting desktop color-scheme to prefer-dark"
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
else
    warn "gsettings/color-scheme unavailable here (no session bus or schema?); set it later:"
    warn "  gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
fi

# Emacs key theme for GTK text fields (GTK2/GTK3 only — see header note).
stow_pkg gtk
