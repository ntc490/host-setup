#!/usr/bin/env bash
# fish shell + a config mirroring .zshrc (git/eza abbrs, ssh-agent link) + zoxide.
# Leaves the login shell alone: zsh.sh switches it back to zsh whenever it
# isn't zsh.
source "$(dirname "$0")/../lib/common.sh"
require_supported

for t in fish zoxide; do
    command -v "$t" >/dev/null 2>&1 || install_tool "$t"
done

# Real directories, so stow links the files inside rather than folding
# ~/.config/fish into one symlink; fish (fish_variables) and tools write here.
FISH_DIR="$HOME/.config/fish"
mkdir -p "$FISH_DIR"/{conf.d,functions,completions}
stow_pkg fish

# herdr ships fish completions; generate them for whatever version is installed.
if command -v herdr >/dev/null 2>&1; then
    log "Writing herdr fish completions"
    herdr completion fish > "$FISH_DIR/completions/herdr.fish"
fi

# Carry oh-my-zsh's z history over, once (zoxide refuses to import into a
# non-empty database).
if command -v zoxide >/dev/null 2>&1 && [ -f "$HOME/.z" ] \
        && [ -z "$(zoxide query --list 2>/dev/null)" ]; then
    log "Importing ~/.z into zoxide"
    # zoxide 0.10 made the source a subcommand; distro packages may be older.
    zoxide import z 2>/dev/null || zoxide import --from=z "$HOME/.z"
fi
