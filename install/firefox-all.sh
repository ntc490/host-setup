#!/usr/bin/env bash
# firefox-all: a convenience GROUP, not a package. Installs the firefox package
# and then applies the managed config, in that order (config assumes the package
# is present). Each member is also runnable on its own (./setup.sh firefox,
# ./setup.sh firefox-config).
source "$(dirname "$0")/../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"

MEMBERS=(
    firefox
    firefox-config
)

for m in "${MEMBERS[@]}"; do
    log "----- $m -----"
    "$HERE/${m}.sh"
done
