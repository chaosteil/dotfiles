{ config, pkgs, ... }:

let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
in
{
  targets.genericLinux.enable = true;

  # Buncha desktop apps
  home.packages = with pkgs; [
    blender
    firefox-bin
    ghostty
    godot
    google-chrome
    openscad
    spotify
    zoom-us
  ];

  xdg.configFile."i3".source = link "i3/.config/i3";
}
