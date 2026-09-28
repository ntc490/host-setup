#!/usr/bin/env bash
# fastfetch: system info shown at shell startup (invoked from .zshrc if present).
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool fastfetch   # not in every distro's repos; skipped with a warning if absent
