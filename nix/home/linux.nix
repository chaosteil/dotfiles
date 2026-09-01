{ pkgs, link, ... }:

{
  targets.genericLinux.enable = true;

  # Buncha desktop apps
  home.packages = with pkgs; [
    blender
    firefox-bin
    ghostty
    godot
    google-chrome
    openscad-unstable
    spotify
    zoom-us
  ];

  xdg.configFile."i3".source = link "i3/.config/i3";
}
