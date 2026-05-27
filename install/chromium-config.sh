#!/usr/bin/env bash
# chromium-config: a system-wide managed Chromium policy (support file in
# install/chromium/). Assumes the chromium package is installed (run chromium.sh
# first, or chromium-all.sh for both). A single policy JSON:
#   * disables the built-in password manager (use Bitwarden instead)
#   * turns off usage metrics + crash reporting, search suggestions, URL-keyed
#     anonymized data collection, the spellcheck web service, and background mode
#   * keeps Safe Browsing at "standard" (1), not the more data-sharing "enhanced"
#   * stops the "make Chromium your default browser" prompt (it's a secondary
#     browser here)
#   * normal-installs the extensions below (removable, unlike force-install)
# Dark mode is NOT handled here: Chromium follows the desktop color-scheme via
# xdg-desktop-portal, set to prefer-dark by the arch-niri `appearance` module.
#
# Extension IDs (verify against the Chrome Web Store URL if one stops installing
# — the ID is the 32-char string in the store link):
#   nngceckbapebfimnlniiiahkandclblb  Bitwarden
#   ddkjiahejlhfcafbddmgiahcphecmpfh  uBlock Origin Lite  (MV3 — classic uBO is
#                                     being phased out on current Chromium)
#   dbepggeogbaibhgnhhndojpepiihcmeb  Vimium
#   nffaoalbilbmmfgbnbgppjihopabppdk  Video Speed Controller
#
# Chromium reads every *.json in the managed dir as a FLAT policy object (note:
# NOT wrapped in a "policies" key, unlike Firefox — and strict JSON, no comments).
# It lives under /etc, so it survives package upgrades. This managed-dir path is
# the standard one across Chromium packagings (Arch, Debian .deb).
source "$(dirname "$0")/../lib/common.sh"
require_supported

HERE="$(cd "$(dirname "$0")" && pwd)"

install_system_file "$HERE/chromium/policies.json" /etc/chromium/policies/managed/host-setup.json

log "chromium configured: no built-in password manager, metrics/crash reporting"
log "  off, search-suggest/spellcheck/URL-keyed data collection off,"
log "  Bitwarden + uBlock Origin Lite + Vimium + Video Speed Controller."
log "  (Dark UI comes from the desktop color-scheme; see arch-niri appearance.)"
log "  Extensions install on next launch; restart chromium if it's running."
