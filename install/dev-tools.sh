#!/usr/bin/env bash
# Development packages I commonly use (the old mydev.yml playbook).
# Arch equivalents: base-devel covers build-essential/autoconf/libtool/pkgconf;
# clang provides clang-format/clang-tidy.
source "$(dirname "$0")/../lib/common.sh"
require_arch

install_pkgs base-devel net-tools doxygen graphviz cmake clang
