#!/usr/bin/env bash
# rupa's z (directory frecency jumper). Installed as a sourced script in ~/bin;
# the .zshrc PATH includes ~/bin and the oh-my-zsh `z` plugin picks it up.
source "$(dirname "$0")/../lib/common.sh"

install_bin z.sh "$HOME/bin/z.sh"
