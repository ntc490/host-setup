#!/usr/bin/env bash
# Global git configuration: identity, rerere, pull --rebase, push auto-upstream,
# init default branch, column UI, and short aliases. Writes to ~/.gitconfig via
# `git config --global` (idempotent; re-runnable).
source "$(dirname "$0")/../lib/common.sh"

# git itself is a prerequisite for everything else in this repo, but make sure.
command -v git >/dev/null 2>&1 || install_tool git

GIT_NAME="Nathan Crapo"
GIT_EMAIL="1585130+ntc490@users.noreply.github.com"

log "Configuring global git settings"

# Identity
git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Reuse recorded conflict resolutions across rebases/merges.
git config --global rerere.enabled true

# `git pull` rebases instead of creating merge commits.
git config --global pull.rebase true

# First `git push` of a new branch auto-creates the upstream (no
# `--set-upstream` needed).
git config --global push.autoSetupRemote true

# Name the initial branch "master" on `git init` (pin it so git stops warning
# about the unset default).
git config --global init.defaultBranch master

# Show branch/tag/remote listings in columns when writing to a terminal.
git config --global column.ui auto

# Short aliases
git config --global alias.br branch
git config --global alias.st status
git config --global alias.ci commit
git config --global alias.co checkout
