{ config, ... }:

let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
in
{
  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;

  xdg.configFile."i3".source = link "i3/.config/i3";
}
