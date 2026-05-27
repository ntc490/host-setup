#!/usr/bin/env bash
# firefox-config: a system-wide managed Firefox config (support files in
# install/firefox/). Assumes the firefox package is already installed (run
# firefox.sh first, or use firefox-all.sh which does both). Works on a fresh
# machine before any profile exists, using two of Firefox's system-level
# mechanisms:
#   * policies.json — normal-installs uBlock Origin / Bitwarden / Video Speed
#                     Controller / Vimium; disables the built-in password
#                     manager; turns off telemetry, Firefox studies, and Pocket;
#                     enables tracking protection + DNS-over-HTTPS (Quad9, with
#                     .lan/.local sent to system DNS); requests the ja UI locale
#   * autoconfig    — firefox.cfg + defaults/pref/autoconfig.js: no crash-report
#                     submission, no sponsored/suggested content, HTTPS-Only mode
#                     (no per-profile prefs). Dark UI now follows the desktop
#                     color-scheme (arch-niri appearance), not this config.
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

log "firefox configured: ja UI, no built-in password manager,"
log "  telemetry/studies/crash/Pocket off, tracking protection on,"
log "  DoH via Quad9 (.lan/.local excluded), HTTPS-Only, no sponsored content,"
log "  uBlock Origin + Bitwarden + Video Speed Controller + Vimium."
log "  Extensions download on first launch; restart firefox if it's running."
