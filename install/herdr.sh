#!/usr/bin/env bash
# herdr (terminal workspace manager for AI agents) + config.toml + its plugins.
source "$(dirname "$0")/../lib/common.sh"
require_supported

# Works on Linux and macOS. Plugin build/runtime deps: cargo builds
# herdr-navigator, python3 runs claude-usage, jq is used by worktrunk's actions.
[ "$DISTRO_FAMILY" = macos ] || install_tool curl   # macOS ships curl
install_tool cargo
install_tool python3
install_tool jq

# herdr isn't packaged anywhere; the official installer drops a checksummed
# release binary in ~/.local/bin. Only run it when missing — `herdr update`
# handles upgrades after that.
HERDR="$HOME/.local/bin/herdr"
if command -v herdr >/dev/null 2>&1; then
    HERDR="$(command -v herdr)"
    log "herdr already installed ($("$HERDR" --version))"
else
    log "Installing herdr from herdr.dev"
    curl -fsSL https://herdr.dev/install.sh | sh
fi

# herdr keeps sockets, logs, sessions, and plugin checkouts in ~/.config/herdr.
# Create it first so stow links only config.toml instead of folding the whole
# directory into the repo.
mkdir -p "$HOME/.config/herdr"
stow_pkg herdr

# Plugins, as OWNER/REPO. config.toml's "$claude_usage" sidebar row comes from
# herdr-claude-usage. worktrunk also needs the `wt` CLI on PATH.
PLUGINS=(
    thanhdat77/herdr-navigator
    persiyanov/herdr-reviewr
    alejodelosrios/herdr-claude-usage
    devashish2203/herdr-worktrunk
)
installed="$("$HERDR" plugin list 2>/dev/null || true)"
for p in "${PLUGINS[@]}"; do
    if grep -qF "[github:$p@" <<<"$installed"; then
        log "herdr plugin $p already installed"
    else
        log "herdr plugin install $p"
        "$HERDR" plugin install -y "$p" || warn "herdr plugin $p failed to install"
    fi
done
command -v wt >/dev/null 2>&1 || warn "worktrunk (wt) not on PATH; the herdr-worktrunk plugin needs it"

# Claude Code hooks that report agent state to herdr's sidebar/attention queue.
if [[ -d "$HOME/.claude" ]]; then
    log "herdr integration install claude"
    "$HERDR" integration install claude || warn "herdr claude integration failed"
fi
