# fish config, mirroring .zshrc. Git abbreviations (generated from oh-my-zsh's
# git plugin) and the ssh-agent socket handling live in conf.d/.

# PATH: Homebrew (zsh gets it from ~/.zprofile), then ~/bin and ~/.local/bin
# in front, as in .zshrc. --path edits PATH for this shell only, rather than
# fish's universal fish_user_paths, so the repo stays the source of truth.
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end
fish_add_path --global --move --path $HOME/bin $HOME/.local/bin

set -gx EDITOR emacs

status is-interactive; or return

# Greeting banner, only if fastfetch is installed (it's an optional component).
function fish_greeting
    command -q fastfetch; and fastfetch
end

if command -q eza
    abbr -a ls 'eza --color=always --icons=always --group-directories-first --git'
    abbr -a l 'eza -lah --color=always --icons=always --group-directories-first --git'
    abbr -a la 'eza -la --color=always --icons=always --group-directories-first --git'
    abbr -a ll 'eza -l --color=always --icons=always --group-directories-first --git'
    abbr -a lt 'eza -aT --color=always --icons=always --group-directories-first --git'
end

# Ctrl-R history, Ctrl-T file and Alt-C cd pickers.
command -q fzf; and fzf --fish | source
# `z` jumping, standing in for oh-my-zsh's z plugin (install/fish.sh imports ~/.z).
command -q zoxide; and zoxide init fish | source
