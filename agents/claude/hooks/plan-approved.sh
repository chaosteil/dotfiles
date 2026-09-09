#!/usr/bin/env bash
# PostToolUse hook for ExitPlanMode. The user approved the plan. Tell Claude
# to hand the implementation to the implementer agent, and to isolate the
# work when other agents share the repository.
set -euo pipefail

input=$(cat)
list=$("$(dirname "$0")/neighbours.sh" <<<"$input")

isolation="No other agent works in this repository. Run the implementer in this checkout."
if [ -n "$list" ]; then
  isolation="Other agents work in this repository:
$list
Start the implementer with isolation: worktree. Do not edit files in this checkout yourself."
fi

context="The user approved the plan. Do not implement it yourself.

1. Start the \`implementer\` agent with the Agent tool. Put the full plan in the prompt, word for word. Add the repository path and the test commands.
2. $isolation
3. Start one implementer for the whole plan. Do not split the plan across agents.
4. When the implementer reports, read its report and its diff. Then report the outcome to the user in a few sentences.
5. If the implementer worked in a worktree, its commits sit on the commit that this checkout branched from. Run \`jj --no-pager log -r '<base>::'\` to see them. If the working copy here is empty, run \`jj rebase -r @ -d <top commit>\` so that this checkout includes the work. Then run \`jj workspace forget <name>\` and delete the worktree directory."

jq -n --arg c "$context" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $c}}'
