#!/usr/bin/env bash
# Graphical Emacs + personal config, with its bundled binaries compiled via make.
source "$(dirname "$0")/../lib/common.sh"
require_supported

# Arch uses emacs-wayland (the pgtk build: native Wayland, also works on X);
# Debian/RHEL use the plain `emacs` metapackage (graphical).
install_tool emacs

EMACS_D="$HOME/.emacs.d"
clone_or_update https://github.com/ntc490/emacs.d "$EMACS_D" --recursive

# The config ships submodules with C/elisp helpers built via a top-level make.
if [[ -f "$EMACS_D/Makefile" ]]; then
    log "Building Emacs config helpers (make in $EMACS_D)"
    make -C "$EMACS_D"
else
    warn "No Makefile in $EMACS_D; skipping make step"
fi
