{
  config,
  lib,
  pkgs,
  link,
  namedPackages,
  ...
}:

{
  targets.genericLinux.enable = true;

  # Buncha desktop apps
  home.packages =
    namedPackages [
      "blender"
      "firefox-bin"
      "ghostty"
      "godot"
      "google-chrome"
      "openscad-unstable"
      "spotify"
      "zoom-us"
    ]
    ++ lib.optional config.local.privateAssets pkgs.private-assets;

  fonts.fontconfig.enable = lib.mkIf config.local.privateAssets true;

  # The ssh-agent.socket unit of the host, also for systemd user services.
  home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  systemd.user.sessionVariables.SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/ssh-agent.socket";
  xdg.configFile."systemd/user/sockets.target.wants/ssh-agent.socket".source =
    config.lib.file.mkOutOfStoreSymlink "/usr/lib/systemd/user/ssh-agent.socket";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*".AddKeysToAgent = "yes";
  };

  xdg.configFile."i3".source = link "i3/.config/i3";
}
