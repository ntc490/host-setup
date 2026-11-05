# Port of oh-my-zsh's git_current_branch (used by the ggpush/gpsup/... abbrs):
# the branch name, or the short commit hash on a detached HEAD.
function git_current_branch -d "Current git branch"
    set -l ref (command git symbolic-ref --quiet HEAD 2>/dev/null)
    set -l ret $status
    if test $ret -ne 0
        test $ret -eq 128; and return   # not a git repo
        set ref (command git rev-parse --short HEAD 2>/dev/null); or return
    end
    string replace -- refs/heads/ '' $ref
end
