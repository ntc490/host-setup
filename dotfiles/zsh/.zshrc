export PATH=$HOME/bin:$HOME/.local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
# Use powerline
USE_POWERLINE="true"

# Greeting banner, only if fastfetch is installed (it's an optional component).
if command -v fastfetch > /dev/null 2>&1; then
    fastfetch
fi

plugins=(git git-extras zsh-autosuggestions zsh-syntax-highlighting tmux history extract colorize docker z)

source $ZSH/oh-my-zsh.sh
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Fall back to systemd's ssh-agent.socket if the session didn't export
# SSH_AUTH_SOCK. environment.d sets this at login, but only when the systemd
# --user manager actually (re)starts — a stale manager (sessions kept alive
# across a re-login) leaves it unset. Only acts when unset, so a forwarded
# agent (ForwardAgent) is never clobbered.
if [ -z "$SSH_AUTH_SOCK" ] && [ -S "${XDG_RUNTIME_DIR}/ssh-agent.socket" ]; then
    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
fi

# Predictable SSH authentication socket location (stable path for tmux reattach).
SOCK="${HOME}/.ssh-agent-tmux"
if test $SSH_AUTH_SOCK && [ $SSH_AUTH_SOCK != $SOCK ]
then
    ln -sf $SSH_AUTH_SOCK $SOCK
    export SSH_AUTH_SOCK=$SOCK
fi

clip() { printf '\033]52;c;%s\a' "$(cat "$@" | base64 | tr -d '\n')"; }

export EDITOR='emacs -nw'

alias ls='eza --color=always --icons=always --group-directories-first --git'
alias l='eza -lah --color=always --icons=always --group-directories-first --git'
alias la='eza -la --color=always --icons=always --group-directories-first --git'
alias ll='eza -l --color=always --icons=always --group-directories-first --git'
alias lt='eza -aT --color=always --icons=always --group-directories-first --git'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
