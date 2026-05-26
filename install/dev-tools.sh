#!/usr/bin/env bash
# dev-tools: a convenience GROUP, not a package. Runs the individual
# development-tool install scripts (each is also runnable on its own, e.g.
# `./setup.sh cmake`). This is the old mydev.yml set.
source "$(dirname "$0")/../lib/common.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"

MEMBERS=(
    base-devel
    net-tools
    doxygen
    graphviz
    cmake
    clang-tools   # clang -> clang-format, clang-tidy
)

for m in "${MEMBERS[@]}"; do
    log "----- $m -----"
    "$HERE/${m}.sh"
done
