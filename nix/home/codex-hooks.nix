# The hooks of Codex, for programs.codex.hooks. Each event runs
# codex-program-status, which reports the state of Codex to the terminal.
# Some events also run agent-panes, which keeps the Rex layout: subagent
# panes and repo columns. A Bash call also runs codeview-zoom, which lets a
# codeview review fill the Rex window. The start of a session also runs
# codex-session-start, which tells Codex about other agents in the
# repository.
#
# Codex runs a hook only after the user trusts it in /hooks, and the trust
# is for the exact hook text. The commands are in the profile (bin), not in
# the nix store, so the text and the trust stay the same after a rebuild.
{ lib, bin }:
let
  # The events that run agent-panes, with the timeout in seconds.
  panes = {
    SessionStart = 5;
    UserPromptSubmit = 5;
    PostToolUse = 5;
    SubagentStart = 5;
    SubagentStop = 5;
    SessionEnd = 3;
  };
in
lib.genAttrs
  [
    "SessionStart"
    "UserPromptSubmit"
    "PreToolUse"
    "PermissionRequest"
    "PostToolUse"
    "Stop"
    "Interrupt"
    "PreCompact"
    "PostCompact"
    "SubagentStart"
    "SubagentStop"
    "SessionEnd"
  ]
  (
    event:
    [
      {
        hooks = [
          {
            type = "command";
            command = "${bin}/codex-program-status";
            timeout = 3;
          }
        ]
        ++ lib.optional (panes ? ${event}) {
          type = "command";
          command = "${bin}/agent-panes hook codex";
          timeout = panes.${event};
        };
      }
    ]
    ++ lib.optional (event == "SessionStart") {
      matcher = "startup|resume";
      hooks = [
        {
          type = "command";
          command = "${bin}/codex-session-start";
          timeout = 10;
        }
      ];
    }
    ++ lib.optional (event == "PostToolUse") {
      matcher = "^Bash$";
      hooks = [
        {
          type = "command";
          command = "${bin}/codeview-zoom";
          timeout = 5;
        }
      ];
    }
  )
