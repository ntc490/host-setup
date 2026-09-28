#!/usr/bin/env bash
# less: terminal pager. Increasingly shipped as a separate package rather than
# part of the base system, so install it explicitly.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool less
