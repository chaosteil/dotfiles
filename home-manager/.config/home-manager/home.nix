{ config, pkgs, user, ... }:

let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = user;
  home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${user}" else "/home/${user}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    (rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" "rust-analyzer" ];
    })
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    atuin
    bat
    cmake
    cowsay
    ctags
    curl
    delta
    direnv
    eza
    fd
    ffmpeg
    gh
    git
    git-lfs
    go
    htop
    jjui
    jq
    jujutsu
    just
    kubectl
    python3
    rar
    ripgrep
    shellcheck
    stow
    tig
    tmux
    watchman
    yamllint
    yarn
    zellij
    zoxide

    # Some cargo items
    cargo-audit
    cargo-cache
    cargo-generate
    cargo-dist
    cargo-edit
    cargo-flamegraph
    cargo-nextest
    cargo-update
  ];

  xdg.configFile = {
    "home-manager".source = link "home-manager/.config/home-manager";
    "aerospace".source = link "aerospace/.config/aerospace";
    "atuin".source = link "atuin/.config/atuin";
    "fish".source = link "fish/.config/fish";
    "nvim".source = link "nvim/.config/nvim";
    "ghostty".source = link "ghostty/.config/ghostty";
    "jj".source = link "jj/.config/jj";
    "zellij".source = link "zellij/.config/zellij";
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
    ".claude/CLAUDE.md".source = link "claude/.claude/CLAUDE.md";
    ".claude/skills".source = link "claude/.claude/skills";
    ".gitconfig".source = link "git/.gitconfig";
    ".gitignore_global".source = link "git/.gitignore_global";
    ".oh-my-zsh".source = link "zsh/.oh-my-zsh";
    ".config/starship.toml".source = link "starship/.config/starship.toml";
    ".config/starship-jj".source = link "starship/.config/starship-jj";
    ".tmux".source = link "tmux/.tmux";
    ".tmux.conf".source = link "tmux/.tmux.conf";
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.fish.enable = true;
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

  # We allow unfree licenses
  nixpkgs.config.allowUnfree = true;
}
