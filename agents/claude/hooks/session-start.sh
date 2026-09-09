#!/usr/bin/env bash
# SessionStart hook. If other agents work in this repository, tell Claude
# to implement in a worktree.
set -euo pipefail

input=$(cat)
list=$("$(dirname "$0")/neighbours.sh" <<<"$input")
[ -n "$list" ] || exit 0

event=$(jq -r '.hook_event_name' <<<"$input")
context="Other agents work in this repository:
$list

Do not edit files in this checkout. Before the first edit, isolate the work:
- If you hand the work to a subagent, start it with isolation: worktree.
- If you edit yourself, call EnterWorktree first.
In a jj repository the worktree is a jj workspace. Do not run git."

jq -n --arg e "$event" --arg c "$context" \
  '{hookSpecificOutput: {hookEventName: $e, additionalContext: $c}}'
