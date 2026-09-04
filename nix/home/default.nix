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

{
  # Symlink into the repository.
  _module.args.link =
    path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";

  programs.home-manager.enable = standalone;

  home.username = user;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${user}" else "/home/${user}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows to install Nix packages into the
  # environment. The names live in packages.nix. The rust toolchain is
  # not a plain nixpkgs name, so it stays here.
  home.packages = [
    (pkgs.rust-bin.stable.latest.default.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
      ];
    })
  ]
  ++ namedPackages (import ./packages.nix ++ config.local.apps);

  xdg.configFile = {
    "home-manager".source = link "nix";
    "fish/config.fish".enable = false;

    "atuin".source = link "atuin/.config/atuin";
    "fish".source = link "fish/.config/fish";
    "nvim".source = link "nvim/.config/nvim";
    "ghostty".source = link "ghostty/.config/ghostty";
    "zellij".source = link "zellij/.config/zellij";

    # jj reads config.toml first and then conf.d/*.toml in name order. The
    # repository keeps config.toml, and this module writes the identity into
    # conf.d. A value in conf.d wins. Each entry is a separate link, because
    # a link of the whole directory has no space for the generated file.
    "jj/config.toml".source = link "jj/.config/jj/config.toml";
    "jj/conf.d/10-identity.toml".source = (pkgs.formats.toml { }).generate "jj-identity.toml" (
      {
        user = {
          name = config.local.fullName;
          email = config.local.email;
        };
        templates.git_push_bookmark = ''"${config.local.bookmarkPrefix}/" ++ change_id.short()'';
        revset-aliases."immutable_heads()" =
          "builtin_immutable_heads() | (bookmarks(glob:'${config.local.bookmarkPrefix}/*'))";
      }
      # Only add this section if we have a signingKey.
      // lib.optionalAttrs (config.local.signingKey != null) {
        signing = {
          backend = "ssh";
          behavior = "own";
          key = config.local.signingKey;
        };
      }
    );
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".claude/CLAUDE.md".source = link "agents/AGENTS.md";
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
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/dominykas/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # The module makes one link for each skill, so the skills of this
  # repository and the skills of the flake inputs share ~/.claude/skills.
  # A skill of this repository goes through the nix store: an edit needs a
  # rebuild, and jj must track a new file before nix reads it.
  programs.claude-code = {
    enable = true;
    skills = {
      simple-english = "${inputs.skill-simple-english}/skills/simple-english";
      jujutsu = "${inputs.skill-jujutsu}/jujutsu";
      jujutsu-stacks = ../../agents/skills/jujutsu-stacks;
      jujutsu-workspaces = ../../agents/skills/jujutsu-workspaces;
    };
  };

  programs.fish.enable = true;
  programs.man.package = pkgs.man;
  programs.neovim = {
    enable = true;
    sideloadInitLua = true;
    extraPackages = with pkgs; [
      bash-language-server
      delve
      dockerfile-language-server
      eslint_d
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
