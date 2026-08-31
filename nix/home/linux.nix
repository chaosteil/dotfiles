{ config, pkgs, ... }:

let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
in
{
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile."i3".source = link "i3/.config/i3";
}
