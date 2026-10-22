{
  config,
  inputs,
  lib,
  pkgs,
  user,
  standalone,
  link,
  namedPackages,
  ...
}:

let
  # The instructions for every coding agent. Each harness reads the same
  # file through its own link.
  agentInstructions = link "agents/AGENTS.md";

  # The name that programs.claude-code gives to its settings file.
  claudeSettings = "${config.programs.claude-code.configDir}/settings.json";

  skills = {
    simple-english = "${inputs.skill-simple-english}/skills/simple-english";
    jujutsu = "${inputs.skill-jujutsu}/jujutsu";
    bevy = "${inputs.skill-bevy}/plugins/tsal/skills/bevy";
    frontend-slides = "${inputs.skill-frontend-slides}/plugins/frontend-slides/skills/frontend-slides";
    jujutsu-stacks = ../../agents/skills/jujutsu-stacks;
    jujutsu-workspaces = ../../agents/skills/jujutsu-workspaces;
    rex-codeview = "${inputs.codeview}/skills/rex-codeview";
  };
in
{
  # Symlink into the repository.
  _module.args.link =
    path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";

  programs.home-manager.enable = standalone;

  home.username = user;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${user}" else "/home/${user}";

  # The Home Manager release that this configuration follows. Read the
  # release notes before you change it.
  home.stateVersion = "26.05";

  # The package names are in packages.nix. The rust toolchain is not a
  # plain nixpkgs name, so it stays here.
  home.packages = [
    (pkgs.rust-bin.stable.latest.default.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
      ];
    })
    pkgs.program-status
  ]
  ++ namedPackages (import ./packages.nix ++ config.local.apps);

  xdg.configFile = {
    "home-manager".source = link "nix";
    "fish/config.fish".enable = false;

    "atuin".source = link "atuin/.config/atuin";
    "fish".source = link "fish/.config/fish";
    "nvim".source = link "nvim/.config/nvim";
    # Separate links, because linux.nix adds ghostty/local.conf.
    "ghostty/config".source = link "ghostty/.config/ghostty/config";
    "ghostty/shaders".source = link "ghostty/.config/ghostty/shaders";
    "zellij".source = link "zellij/.config/zellij";
    "opencode/AGENTS.md".source = agentInstructions;

    # jj reads config.toml first and then conf.d/*.toml in name order. The
    # repository keeps config.toml, and this module writes the identity into
    # conf.d. A value in conf.d wins. Each entry is a separate link, because
    # a link of the whole directory has no space for the generated file.
    "jj/config.toml".source = link "jj/.config/jj/config.toml";
    "jj/conf.d/10-identity.toml".source = (pkgs.formats.toml { }).generate "jj-identity.toml" (
      let
        prefix = config.local.bookmarkPrefix;
      in
      {
        user = {
          name = config.local.fullName;
          email = config.local.email;
        };
        templates.git_push_bookmark = ''"${prefix}/" ++ change_id.short()'';
        # Only the bookmarks under "<prefix>/upstream/" are immutable.
        revset-aliases."immutable_heads()" =
          "builtin_immutable_heads() | (bookmarks(glob:'${prefix}/upstream/*'))";
      }
      # Only add this section if we have a signingKey.
      // lib.optionalAttrs (config.local.signingKey != null) {
        # Sign on push only (git.sign-on-push), so Secretive asks once per push.
        signing = {
          backend = "ssh";
          behavior = "drop";
          key = config.local.signingKey;
        };
      }
    );
  };

  home.file = {
    # Claude Code imports the instructions from ~/.agents, see
    # programs.claude-code below.
    ".agents/AGENTS.md".source = agentInstructions;
    ".codex/AGENTS.md".source = agentInstructions;
    ".gemini/AGENTS.md".source = agentInstructions;
    ".claude/skills/program-status".source = link "agents/claude/plugins/program-status";
    ".gitconfig".source = link "git/.gitconfig";
    ".gitignore_global".source = link "git/.gitignore_global";
    ".oh-my-zsh".source = link "zsh/.oh-my-zsh";
    ".config/starship.toml".source = link "starship/.config/starship.toml";
    ".config/starship-jj".source = link "starship/.config/starship-jj";
    ".tmux.conf".source = link "tmux/.tmux.conf";

    ".tmux/plugins/tmux-cpu".source = "${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu";
    ".tmux/plugins/tmux-sensible".source = "${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible";
    ".tmux/plugins/tmux-pain-control".source =
      "${pkgs.tmuxPlugins.pain-control}/share/tmux-plugins/pain-control";
    ".tmux/plugins/tmux-nova".source = "${pkgs.tmuxPlugins.tmux-nova}/share/tmux-plugins/tmux-nova";
    ".zshenv".source = link "zsh/.zshenv";
    ".zshrc".source = link "zsh/.zshrc";

    # The activation claudeSettings below writes this file.
    "${claudeSettings}".enable = false;
  }
  # Codex, Gemini CLI, OpenCode, Copilot CLI, and Cursor read the skills
  # in ~/.agents/skills. Each skill is one link to its directory.
  // lib.mapAttrs' (
    name: source: lib.nameValuePair ".agents/skills/${name}" { inherit source; }
  ) skills;

  # Claude Code reads only ~/.claude/skills. The module makes one link
  # for each skill, so unmanaged skills can stay in the same directory.
  programs.claude-code = {
    enable = true;

    # Claude Code reads CLAUDE.md, not AGENTS.md. Here we force it.
    context = ''
      @${config.home.homeDirectory}/.agents/AGENTS.md
    '';

    inherit skills;

    agents.implementer = ../../agents/claude/agents/implementer.md;
    hooksDir = ../../agents/claude/hooks;

    settings =
      let
        hook = name: {
          hooks = [
            {
              type = "command";
              command = "${config.home.homeDirectory}/.claude/hooks/${name}";
            }
          ];
        };
      in
      {
        model = "claude-opus-5-5[1m]";
        effortLevel = "xhigh";
        modelSettings."claude-opus-5-5".effortLevel = "high";
        theme = "dark";
        agentPushNotifEnabled = true;
        remoteControlAtStartup = true;
        skipDangerousModePermissionPrompt = true;
        enabledPlugins = {
          "rust-analyzer-lsp@claude-plugins-official" = true;
          "pyright-lsp@claude-plugins-official" = true;
        };

        env.CLAUDE_CODE_SUBAGENT_MODEL = "opus";

        attribution = {
          commit = "";
          pr = "";
          sessionUrl = false;
        };

        hooks = {
          # Tell Claude when other agents work in the same repository.
          SessionStart = [ (hook "session-start.sh" // { matcher = "startup|resume"; }) ];
          # Hand an approved plan to the implementer.
          PostToolUse = [ (hook "plan-approved.sh" // { matcher = "ExitPlanMode"; }) ];
          # A worktree in a jj repository is a jj workspace.
          WorktreeCreate = [ (hook "worktree-create.sh") ];
          WorktreeRemove = [ (hook "worktree-remove.sh") ];
        };
      };
  };

  # Symposium adds its own hooks to the Claude Code settings, so the file
  # must be a normal file. Write the generated settings, then let
  # symposium add its hooks.
  home.activation.claudeSettings =
    let
      symposiumConfig = "${config.xdg.configHome}/symposium/config.toml";
    in
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run mkdir -p "$HOME/.claude"
      run install -m 644 ${config.home.file.${claudeSettings}.source} "$HOME/.claude/settings.json"

      # The hooks that Claude starts find the symposium config through
      # XDG_CONFIG_HOME. The activation can have no value for it.
      export XDG_CONFIG_HOME="${config.xdg.configHome}"

      # Symposium must not update itself over the nix binary. Write the
      # file only once: init keeps the settings in it, and the user can add
      # plugin consent there.
      if [[ ! -e "${symposiumConfig}" ]]; then
        run mkdir -p "${config.xdg.configHome}/symposium"
        run install -m 644 ${pkgs.writeText "symposium-config.toml" "auto-update = \"off\"\n"} "${symposiumConfig}"
      fi

      run ${lib.getExe pkgs.symposium} init --add-agent claude --hook-scope global || warnEcho "symposium did not register its hooks"
    '';

  programs.fish.enable = true;
  programs.man.package = pkgs.man;
  programs.neovim = {
    enable = true;
    sideloadInitLua = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
    extraPackages = with pkgs; [
      bash-language-server
      delve
      dockerfile-language-server
      eslint_d
      go-tools
      gopls
      lua-language-server
      markdownlint-cli
      marksman
      nixd
      nixfmt
      oxfmt
      prettierd
      pyright
      shellcheck
      shfmt
      stylua
      superhtml
      tailwindcss-language-server
      taplo
      typescript-language-server
      vscode-langservers-extracted
      yaml-language-server
      yamlfix
      yamllint
      zls
    ];
  };
}
