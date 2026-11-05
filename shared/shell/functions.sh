nwt() {
  local worktree

  worktree=$(
    git worktree list --porcelain |
    sed -n 's/^worktree //p' |
    fzf
  ) || return

  [[ -n "$worktree" ]] && nvim "$worktree"
}

cwt() {
  local worktree

  worktree=$(
    git worktree list --porcelain |
    sed -n 's/^worktree //p' |
    fzf
  ) || return

  [[ -n "$worktree" ]] && cd "$worktree"
}
