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

# ~/.ssh/rc points ~/.ssh/agent.sock at the agent of the latest SSH login that
# carries an allowlisted key. Use that stable path when the inherited socket is
# missing or dead (a herdr pane outliving the connection it started under), or
# is the very agent the link points at, so the shell keeps working after that
# connection ends. A live, different agent (one rc declined, or a desktop
# session's own agent) is left alone.
if [ -S "$HOME/.ssh/agent.sock" ]; then
    if [ ! -S "$SSH_AUTH_SOCK" ] || [ "$SSH_AUTH_SOCK" -ef "$HOME/.ssh/agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    fi
fi

# Fall back to systemd's ssh-agent.socket if nothing set SSH_AUTH_SOCK.
# environment.d sets it at a desktop login, but only when the systemd --user
# manager (re)starts; a stale manager leaves it unset.
if [ -z "$SSH_AUTH_SOCK" ] && [ -S "${XDG_RUNTIME_DIR}/ssh-agent.socket" ]; then
    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
fi

clip() { printf '\033]52;c;%s\a' "$(cat "$@" | base64 | tr -d '\n')"; }

export EDITOR='emacs -nw'

alias ls='eza --color=always --icons=always --group-directories-first'
alias lsg='eza --color=always --icons=always --group-directories-first --git'
alias l='eza -lah --color=always --icons=always --group-directories-first'
alias lg='eza -lah --color=always --icons=always --group-directories-first --git'
alias la='eza -la --color=always --icons=always --group-directories-first'
alias lag='eza -la --color=always --icons=always --group-directories-first --git'
alias ll='eza -l --color=always --icons=always --group-directories-first'
alias llg='eza -l --color=always --icons=always --group-directories-first --git'
alias llm='eza -l --color=always --icons=always --group-directories-first -s modified'
alias llmg='eza -l --color=always --icons=always --group-directories-first -s modified --git'
alias lt='eza -aT --color=always --icons=always --group-directories-first'
alias ltg='eza -aT --color=always --icons=always --group-directories-first --git'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
