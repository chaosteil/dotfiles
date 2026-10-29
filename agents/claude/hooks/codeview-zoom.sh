#!/usr/bin/env bash
# PostToolUse hook for Bash. When the rex-codeview skill opens a review, zoom
# the review pane, so that it fills the Rex window. The zoom ends when the
# pane closes.
set -euo pipefail

input=$(cat)
# "codeview-review open" prints the handle of the review on its last line.
handle=$(jq -r '
  select((.tool_input.command // "") | test("codeview-review open"))
  | (.tool_response.stdout? // "") | split("\n") | map(select(. != "")) | last // ""
' <<<"$input")
[ -n "$handle" ] && [ -f "$handle/label" ] || exit 0

rex zoom -b "$(cat "$handle/label")" ${REX_SESSION:+-s "$REX_SESSION"} --on >/dev/null 2>&1 || true
