# Same agent handling as .zshrc. Interactive shells only, like .zshrc: a
# one-off `ssh host cmd` must not repoint the shared socket at an agent that
# goes away when that command exits.
status is-interactive; or return

# Fall back to systemd's ssh-agent.socket if the session didn't export
# SSH_AUTH_SOCK (a stale systemd --user manager can leave it unset). Only acts
# when unset, so a forwarded agent (ForwardAgent) is never clobbered.
if not set -q SSH_AUTH_SOCK; and set -q XDG_RUNTIME_DIR; and test -S $XDG_RUNTIME_DIR/ssh-agent.socket
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end

# Predictable socket path: each new login repoints the link at its own agent,
# and shells inside long-lived tmux/herdr sessions keep using the link, so
# they reconnect to whichever machine you SSHed in from most recently.
set -l sock $HOME/.ssh-agent-tmux
if set -q SSH_AUTH_SOCK; and test "$SSH_AUTH_SOCK" != $sock
    ln -sf $SSH_AUTH_SOCK $sock
    set -gx SSH_AUTH_SOCK $sock
end
