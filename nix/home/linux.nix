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

  xdg.configFile."i3".source = link "i3/.config/i3";
}
