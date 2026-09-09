#!/usr/bin/env bash
# Print the other agent sessions that work in the same repository.
#
# Input: the hook JSON on stdin (needs "cwd", "session_id").
# Output: one line for each other session. No output means no neighbours.
#
# Sources:
# - Claude Code writes ~/.claude/sessions/<pid>.json for each live session.
# - lsof finds other agent processes (codex, gemini, opencode, copilot).
set -euo pipefail

input=$(cat)
cwd=$(jq -r '.cwd' <<<"$input")
me=$(jq -r '.session_id // empty' <<<"$input")

# The repository root of a directory. Falls back to the directory itself.
root_of() {
  (
    cd "$1" 2>/dev/null || exit 1
    jj --ignore-working-copy workspace root 2>/dev/null \
      || git rev-parse --show-toplevel 2>/dev/null \
      || pwd
  )
}

root=$(root_of "$cwd") || exit 0

# A session that already runs in a worktree is isolated.
case "$root" in */.claude/worktrees/*) exit 0 ;; esac

sessions_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/sessions"
for f in "$sessions_dir"/*.json; do
  [ -e "$f" ] || continue
  IFS=$'\t' read -r pid sid scwd name status \
    < <(jq -r '[.pid, .sessionId, .cwd, .name, .status] | @tsv' "$f" 2>/dev/null) \
    || continue
  [ -n "$pid" ] || continue
  [ "$sid" = "$me" ] && continue
  kill -0 "$pid" 2>/dev/null || continue
  sroot=$(root_of "$scwd") || continue
  [ "$sroot" = "$root" ] || continue
  echo "Claude Code session \"$name\" (pid $pid, $status) in $scwd"
done

# Other agent processes with a working directory inside the repository.
# lsof exits 1 when it finds no process, so the "|| true" keeps the hook alive.
if command -v lsof >/dev/null 2>&1; then
  { lsof -a -d cwd -c codex -c gemini -c opencode -c copilot -F pcn 2>/dev/null || true; } \
    | awk -v root="$root" '
      /^p/ { pid = substr($0, 2) }
      /^c/ { cmd = substr($0, 2) }
      /^n/ {
        dir = substr($0, 2)
        if (dir == root || index(dir, root "/") == 1)
          printf "%s process (pid %s) in %s\n", cmd, pid, dir
      }'
fi
