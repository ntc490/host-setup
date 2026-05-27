#!/usr/bin/env bash
# System locale. Two separate steps that are easy to conflate:
#   1. *generate* the locales we want (locale-gen / glibc) — makes them available
#   2. *activate* one as the default LANG (/etc/locale.conf via localectl)
# Doing only (1) leaves you on systemd's C.UTF-8 fallback, which is the trap
# this module exists to avoid.
source "$(dirname "$0")/../lib/common.sh"
require_supported

LANG_DEFAULT="en_US.UTF-8"
LOCALES=("en_US.UTF-8 UTF-8" "ja_JP.UTF-8 UTF-8")   # ja_JP for Japanese input

# ensure_locale "<glibc> <charset>" — uncomment or append the line in locale.gen.
ensure_locale() {
    local entry=$1 key
    key=${entry%% *}                 # "en_US.UTF-8"
    key=${key//./\\.}                # escape dots for regex
    if grep -qE "^${key}[[:space:]]" /etc/locale.gen; then
        return 0                     # already enabled
    elif grep -qE "^#[[:space:]]*${key}[[:space:]]" /etc/locale.gen; then
        $SUDO sed -i -E "s/^#[[:space:]]*(${key}[[:space:]].*)/\1/" /etc/locale.gen
    else
        printf '%s\n' "$entry" | $SUDO tee -a /etc/locale.gen >/dev/null
    fi
}

# 1. Generate. Arch/Debian use /etc/locale.gen + locale-gen; RHEL ships locales
#    via glibc and has no locale.gen, so just rely on those there.
if [ -f /etc/locale.gen ]; then
    for entry in "${LOCALES[@]}"; do ensure_locale "$entry"; done
    if command -v locale-gen >/dev/null 2>&1; then
        log "Generating locales"
        $SUDO locale-gen
    fi
else
    warn "no /etc/locale.gen here; relying on glibc-provided locales"
fi

# 2. Activate the default locale (this is the step that was missing — writes
#    /etc/locale.conf). Fall back to writing the file directly if localectl
#    isn't usable (e.g. no systemd in a container).
if command -v localectl >/dev/null 2>&1 && localectl status >/dev/null 2>&1; then
    log "Setting system locale LANG=$LANG_DEFAULT"
    $SUDO localectl set-locale "LANG=$LANG_DEFAULT"
else
    log "Writing /etc/locale.conf directly (localectl unavailable)"
    printf 'LANG=%s\n' "$LANG_DEFAULT" | $SUDO tee /etc/locale.conf >/dev/null
fi

log "Locale set. Takes effect at next login (current session stays as-is)."
