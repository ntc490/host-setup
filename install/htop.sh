#!/usr/bin/env bash
# htop: interactive process viewer.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs htop
