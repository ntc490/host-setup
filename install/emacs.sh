#!/usr/bin/env bash
# Graphical Emacs + personal config, with its bundled binaries compiled via make.
source "$(dirname "$0")/../lib/common.sh"
require_supported

# Arch uses emacs-wayland (the pgtk build: native Wayland, also works on X);
# Debian/RHEL use the plain `emacs` metapackage (graphical).
install_tool emacs

EMACS_D="$HOME/.emacs.d"
clone_or_update https://github.com/ntc490/emacs.d "$EMACS_D" --recursive

# The tree-sitter-sources submodule compiles the grammar shared libraries and
# `make install` drops them in ~/.emacs.d/tree-sitter. Building them needs a
# C/C++ toolchain.
TS_DIR="$EMACS_D/tree-sitter-sources"
if [[ -f "$TS_DIR/Makefile" ]]; then
    install_tool base-devel   # gcc/g++/make; idempotent if already present
    log "Building tree-sitter grammars (make install in $TS_DIR)"
    make -C "$TS_DIR" install
else
    warn "No $TS_DIR/Makefile; skipping tree-sitter build"
fi
