{
  config,
  inputs,
  lib,
  pkgs,
  link,
  namedPackages,
  ...
}:

{
  imports = [ ./hyprland.nix ];

  targets.genericLinux.enable = true;

  # Home Manager builds the drivers. system-manager links them.
  targets.genericLinux.gpu.nvidia = lib.mkIf (config.local.nvidia != null) {
    enable = true;
    inherit (config.local.nvidia) version sha256;
  };

  # system-manager owns /run/opengl-driver, not the setup package of the module.
  home.activation.checkExistingGpuDrivers = lib.mkForce (
    lib.hm.dag.entryAnywhere ''
      existing=$(readlink /run/opengl-driver || true)
      if [[ "$existing" != "${config.targets.genericLinux.gpu.drivers}" ]]; then
        warnEcho "/run/opengl-driver does not point to the GPU drivers of this configuration."
        warnEcho "Run:"
        warnEcho "  system-manager switch --flake ~/dotfiles/nix --sudo"
      fi
    ''
  );

  # Buncha desktop apps
  home.packages =
    namedPackages [
      "blender"
      "discord"
      "firefox-bin"
      "ghostty"
      "godot"
      "google-chrome"
      "gvfs"
      "hyprshot"
      "openscad-unstable"
      "playerctl"
      "spotify"
      "thunar"
      "tumbler"
      "wl-clipboard"
      "zoom-us"
    ]
    ++ [ inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.default ]
    ++ [
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-color-emoji
      pkgs.nerd-fonts.symbols-only
    ]
    ++ lib.optional config.local.privateAssets pkgs.private-assets
    # Uses nix, pacman, jj and the switch commands from the user PATH.
    ++ lib.optional (config.local.nvidia != null) (
      pkgs.writeShellApplication {
        name = "nvidia-sync";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
          pkgs.jq
        ];
        text = builtins.readFile ../scripts/nvidia-sync;
      }
    );

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # hyprland.nix reads enable.
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  # The nix NVIDIA libraries must match the host driver.
  home.activation.checkNvidiaVersion = lib.mkIf (config.local.nvidia != null) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! grep -qF ' ${config.local.nvidia.version} ' /proc/driver/nvidia/version 2>/dev/null; then
        warnEcho "The NVIDIA driver is not version ${config.local.nvidia.version}."
        warnEcho "Run nvidia-sync. Then reboot the computer."
      fi
    ''
  );

  fonts.fontconfig.enable = true;

  # 10.5pt on macOS (72 DPI) is 7.875pt on Linux (96 DPI).
  xdg.configFile."ghostty/local.conf".text = ''
    font-size = 7.875
  '';

  # The ssh-agent.socket unit of the host, also for systemd user services.
  home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  systemd.user.sessionVariables.SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/ssh-agent.socket";
  xdg.configFile."systemd/user/sockets.target.wants/ssh-agent.socket".source =
    config.lib.file.mkOutOfStoreSymlink "/usr/lib/systemd/user/ssh-agent.socket";

  # gvfs gives Thunar USB mounts and the trash.
  home.sessionVariables.GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules";
  systemd.user.sessionVariables.GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules";
  # dbus-broker starts these services only through their systemd units.
  systemd.user.packages = [
    pkgs.gvfs
    pkgs.tumbler
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*".AddKeysToAgent = "yes";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };

  xdg.configFile."i3".source = link "i3/.config/i3";
}
