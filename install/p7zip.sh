#!/usr/bin/env bash
# p7zip: 7-Zip archiver (the `7z` CLI). distro_pkg maps this to the right
# package per distro -- on Arch it's the official "7zip" port, on Debian
# p7zip-full, on RHEL/EPEL p7zip.
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool p7zip
