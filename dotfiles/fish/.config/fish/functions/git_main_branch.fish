# Port of oh-my-zsh's git_main_branch (used by the gcm/grbm/... abbrs):
# the first of the common main-branch names that exists locally or on
# origin/upstream, else the remote HEAD, else master.
function git_main_branch -d "Name of the repo's main branch"
    command git rev-parse --git-dir &>/dev/null; or return
    for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}
        if command git show-ref -q --verify $ref
            string replace -r '.*/' '' -- $ref
            return 0
        end
    end
    for remote in origin upstream
        set -l ref (command git rev-parse --abbrev-ref $remote/HEAD 2>/dev/null)
        if string match -q -- "$remote/*" $ref
            string replace -- "$remote/" '' $ref
            return 0
        end
    end
    echo master
    return 1
end
