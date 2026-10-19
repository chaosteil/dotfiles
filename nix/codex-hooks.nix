# The hooks of Codex, as the text of /etc/codex/hooks.json. Each event runs
# codex-program-status, which reports the state of Codex to the terminal.
# The file is in /etc, so Codex runs the hooks without a trust step.
{ lib, pkgs }:
builtins.toJSON {
  hooks =
    lib.genAttrs
      [
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
      (_: [
        {
          hooks = [
            {
              type = "command";
              command = lib.getExe pkgs.codex-program-status;
              timeout = 3;
            }
          ];
        }
      ]);
}
