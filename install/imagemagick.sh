#!/usr/bin/env bash
# imagemagick: image conversion/display library + CLI. Used by Emacs for image
# rendering (image-dired, inline images). Package is "imagemagick" on Arch/Debian
# and "ImageMagick" on Fedora/RHEL (see distro_pkg mapping).
source "$(dirname "$0")/../lib/common.sh"
require_supported

install_tool imagemagick
