#!/usr/bin/env bash
# firefox: web browser. Debian ships it as firefox-esr (see distro_pkg mapping).
# Package only — see firefox-config.sh for the managed config, or firefox-all.sh
# to do both.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool firefox
