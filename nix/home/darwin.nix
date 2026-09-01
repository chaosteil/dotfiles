{
  lib,
  pkgs,
  standalone,
  link,
  ...
}:

{
  targets.darwin.copyApps.directory = "Applications/Nix";

  xdg.configFile."aerospace".source = link "aerospace/.config/aerospace";

  # Under nix-darwin the system installs these apps into /Applications.
  home.packages = lib.optionals standalone (import ../darwin/apps.nix pkgs);
}
