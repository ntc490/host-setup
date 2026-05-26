#!/usr/bin/env bash
# net-tools: classic networking utilities (ifconfig, netstat, route, ...).
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool net-tools
