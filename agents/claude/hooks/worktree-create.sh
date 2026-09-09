#!/usr/bin/env bash
# WorktreeCreate hook. In a jj repository, create a jj workspace instead of
# a git worktree. In other repositories, print nothing so that Claude Code
# uses its default git logic.
#
# Input: the hook JSON on stdin ("cwd", "worktree_path").
# Output: the path of the new workspace on stdout.
set -euo pipefail

input=$(cat)
cwd=$(jq -r '.cwd' <<<"$input")
path=$(jq -r '.worktree_path // empty' <<<"$input")
cd "$cwd"

root=$(jj --ignore-working-copy workspace root 2>/dev/null) || exit 0

if [ -z "$path" ]; then
  name=$(jq -r '.name // empty' <<<"$input")
  [ -n "$name" ] || name=$(date +%s)
  path="$root/.claude/worktrees/$name"
fi
name=$(basename "$path")

# Base the workspace on the current tree. When @ is empty, its parent holds
# that tree, and the new @ becomes a sibling instead of a child. A child of a
# changing @ goes stale on every jj command in the main checkout.
base=$(jj --no-pager log --no-graph -r @ -T 'if(empty, "@-", "@")')

mkdir -p "$(dirname "$path")"
jj workspace add --name "$name" -r "$base" "$path" >&2
echo "$path"
