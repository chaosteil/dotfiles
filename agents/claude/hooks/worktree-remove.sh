#!/usr/bin/env bash
# WorktreeRemove hook. Forget the jj workspace and delete its directory.
# Print nothing: Claude Code treats output as an error.
set -euo pipefail

input=$(cat)
path=$(jq -r '.worktree_path // empty' <<<"$input")
[ -n "$path" ] || exit 0

# CAUTION: Delete only a directory under .claude/worktrees.
case "$path" in
  */.claude/worktrees/?*) ;;
  *) echo "worktree-remove: refuse to delete $path" >&2; exit 1 ;;
esac

if [ -d "$path/.jj" ]; then
  jj -R "$path" --ignore-working-copy workspace forget >&2
elif [ -e "$path/.git" ]; then
  git -C "$(jq -r .cwd <<<"$input")" worktree remove --force "$path" >&2
  exit 0
fi

rm -rf "$path"
