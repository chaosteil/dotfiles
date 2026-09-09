#!/usr/bin/env bash
# WorktreeCreate hook. In a jj repository, create a jj workspace at
# ~/code/worktrees/<repo>/<name> instead of a git worktree. In other
# repositories, print nothing so that Claude Code uses its default git logic.
#
# Input: the hook JSON on stdin ("cwd", "worktree_path").
# Output: the path of the new workspace on stdout.
set -euo pipefail

worktrees_dir="$HOME/code/worktrees"

input=$(cat)
cwd=$(jq -r '.cwd' <<<"$input")
path=$(jq -r '.worktree_path // empty' <<<"$input")
cd "$cwd"

root=$(jj --ignore-working-copy workspace root 2>/dev/null) || exit 0

# Claude Code proposes a path under .claude/worktrees. Keep only its name.
name=$(basename "$path")
[ -n "$name" ] || name=$(jq -r '.name // empty' <<<"$input")
[ -n "$name" ] || name=$(date +%s)
path="$worktrees_dir/$(basename "$root")/$name"

base=$(jj --no-pager log --no-graph -r @ -T 'if(empty, "@-", "@")')

mkdir -p "$(dirname "$path")"
jj workspace add --name "$name" -r "$base" "$path" >&2
echo "$path"
