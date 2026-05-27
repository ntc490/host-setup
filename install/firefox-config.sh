#!/usr/bin/env bash
# firefox-config: a system-wide managed Firefox config (support files in
# install/firefox/). Assumes the firefox package is already installed (run
# firefox.sh first, or use firefox-all.sh which does both). Works on a fresh
# machine before any profile exists, using two of Firefox's system-level
# mechanisms:
#   * policies.json — normal-installs uBlock Origin / Bitwarden / Video Speed
#                     Controller, disables the built-in password manager
#                     entirely, and requests the Japanese (ja) UI locale
#   * autoconfig    — firefox.cfg + defaults/pref/autoconfig.js, flipping the
#                     browser chrome into dark mode (no per-profile prefs)
#
# The ja langpack package and the autoconfig paths are Arch-specific, so this
# module is Arch-only and a no-op elsewhere.
source "$(dirname "$0")/../lib/common.sh"
require_supported

HERE="$(cd "$(dirname "$0")" && pwd)"

if [ "$DISTRO_FAMILY" != "arch" ]; then
    warn "firefox-config: Arch-only (langpack + autoconfig paths); skipping on $DISTRO_ID"
    exit 0
fi

# Japanese UI langpack, so RequestedLocales=["ja"] in the policy has something
# to switch to. Arch keeps the langpack version in lockstep with firefox.
install_pkgs firefox-i18n-ja

# Enterprise policy (extensions + password manager + UI locale). Lives under
# /etc, so it survives firefox package upgrades.
install_system_file "$HERE/firefox/policies.json" /etc/firefox/policies/policies.json

# AutoConfig (dark chrome). These live under the application dir and ARE reset
# by a firefox package upgrade — re-running this module restores them.
install_system_file "$HERE/firefox/autoconfig.js" /usr/lib/firefox/defaults/pref/autoconfig.js
install_system_file "$HERE/firefox/firefox.cfg"   /usr/lib/firefox/firefox.cfg

log "firefox configured: dark theme, ja UI, no built-in password manager,"
log "  uBlock Origin + Bitwarden + Video Speed Controller."
log "  Extensions download on first launch; restart firefox if it's running."
