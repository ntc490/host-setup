#!/usr/bin/env bash
# Fonts for the niri desktop — same set wanted on any machine running a terminal
# locally, so the actual logic lives in the top-level fonts module. This thin
# wrapper keeps `./setup.sh arch-niri` self-contained (pulls in fonts even when a
# full ./setup.sh hasn't run first).
source "$(dirname "$0")/../../../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/../../fonts.sh"
