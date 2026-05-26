#!/usr/bin/env bash
# net-tools: classic networking utilities (ifconfig, netstat, route, ...).
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs net-tools
