#!/usr/bin/env bash
# doxygen: source documentation generator.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs doxygen
