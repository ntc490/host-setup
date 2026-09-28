#!/usr/bin/env bash
# rsync: fast incremental file transfer / sync.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool rsync
