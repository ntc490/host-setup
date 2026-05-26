#!/usr/bin/env bash
# clang-format + clang-tidy. On Arch both ship in the `clang` package.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs clang
