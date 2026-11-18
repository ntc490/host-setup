# Same agent handling as .zshrc.
#
# ~/.ssh/rc points ~/.ssh/agent.sock at the agent of the latest SSH login that
# carries an allowlisted key. Use that stable path when the inherited socket is
# missing or dead (a herdr pane outliving the connection it started under), or
# is the very agent the link points at, so the shell keeps working after that
# connection ends. A live, different agent (one rc declined, or a desktop
# session's own agent) is left alone.
set -l link $HOME/.ssh/agent.sock
if test -S $link
    if not set -q SSH_AUTH_SOCK; or not test -S "$SSH_AUTH_SOCK"; or test "$SSH_AUTH_SOCK" -ef $link
        set -gx SSH_AUTH_SOCK $link
    end
end

# Fall back to systemd's ssh-agent.socket if nothing set SSH_AUTH_SOCK.
# environment.d sets it at a desktop login, but only when the systemd --user
# manager (re)starts; a stale manager leaves it unset.
if not set -q SSH_AUTH_SOCK; and set -q XDG_RUNTIME_DIR; and test -S $XDG_RUNTIME_DIR/ssh-agent.socket
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end
