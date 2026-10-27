# The hooks of Codex, as the text of /etc/codex/hooks.json. Each event runs
# codex-program-status, which reports the state of Codex to the terminal.
# Some events also run agent-panes, which keeps the Rex layout: subagent
# panes and repo columns. The file is in /etc, so Codex runs the hooks
# without a trust step.
{ lib, pkgs }:
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
builtins.toJSON {
  hooks =
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
      (event: [
        {
          hooks = [
            {
              type = "command";
              command = lib.getExe pkgs.codex-program-status;
              timeout = 3;
            }
          ]
          ++ lib.optional (panes ? ${event}) {
            type = "command";
            command = "${lib.getExe pkgs.agent-panes} hook codex";
            timeout = panes.${event};
          };
        }
      ]);
}
