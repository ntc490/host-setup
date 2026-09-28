#!/usr/bin/env bash
# chromium-all: a convenience GROUP, not a package. Installs the chromium package
# and then applies the managed policy, in that order (config assumes the package
# is present). Each member is also runnable on its own (./setup.sh chromium,
# ./setup.sh chromium-config).
source "$(dirname "$0")/../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"

MEMBERS=(
    chromium
    chromium-config
)

for m in "${MEMBERS[@]}"; do
    log "----- $m -----"
    "$HERE/${m}.sh"
done
