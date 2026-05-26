#!/usr/bin/env bash
# tldr: simplified, community-driven man pages.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs tldr
