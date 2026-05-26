#!/usr/bin/env bash
# base-devel: Arch build toolchain group (gcc, make, autoconf, libtool,
# pkgconf, etc.) — the equivalent of Debian's build-essential and friends.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs base-devel
