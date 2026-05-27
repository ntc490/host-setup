#!/usr/bin/env bash
# chromium: web browser. Package only — see chromium-config.sh for the managed
# policy, or chromium-all.sh to do both.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool chromium
