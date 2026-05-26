#!/usr/bin/env bash
# graphviz: graph visualization (dot), used by doxygen diagrams among others.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs graphviz
