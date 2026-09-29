#!/usr/bin/env bash
# WorktreeCreate hook. Create the worktree at ~/code/workspaces/<repo>/<name>.
# In a jj repository it is a jj workspace, in a git repository a git worktree.
# The hook replaces the default logic of Claude Code, so it must print a path.
#
# Input: the hook JSON on stdin ("cwd", "worktree_path").
# Output: the path of the new worktree on stdout.
set -euo pipefail

worktrees_dir="$HOME/code/workspaces"

input=$(cat)
cwd=$(jq -r '.cwd' <<<"$input")
path=$(jq -r '.worktree_path // empty' <<<"$input")
cd "$cwd"

# Claude Code proposes a path under .claude/worktrees. Keep only its name.
name=$(basename "$path")
[ -n "$name" ] || name=$(jq -r '.name // empty' <<<"$input")
[ -n "$name" ] || name=$(date +%s)

if root=$(jj --ignore-working-copy workspace root 2>/dev/null); then
  path="$worktrees_dir/$(basename "$root")/$name"
  base=$(jj --no-pager log --no-graph -r @ -T 'if(empty, "@-", "@")')
  mkdir -p "$(dirname "$path")"
  jj workspace add --name "$name" -r "$base" "$path" >&2
elif root=$(git rev-parse --show-toplevel 2>/dev/null); then
  path="$worktrees_dir/$(basename "$root")/$name"
  mkdir -p "$(dirname "$path")"
  git -C "$root" worktree add -b "worktree-$name" "$path" HEAD >&2
else
  echo "worktree-create: $cwd is not in a jj or git repository" >&2
  exit 1
fi

echo "$path"
