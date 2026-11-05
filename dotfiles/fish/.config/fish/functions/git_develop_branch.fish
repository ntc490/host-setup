# Port of oh-my-zsh's git_develop_branch (used by the gcd/grbd/gswd abbrs).
function git_develop_branch -d "Name of the repo's develop branch"
    command git rev-parse --git-dir &>/dev/null; or return
    for branch in dev devel develop development
        if command git show-ref -q --verify refs/heads/$branch
            echo $branch
            return 0
        end
    end
    echo develop
    return 1
end
