#!/usr/bin/env bash
# firefox: web browser. Debian ships it as firefox-esr (see distro_pkg mapping).
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool firefox
