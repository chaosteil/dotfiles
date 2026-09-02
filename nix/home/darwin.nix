{
  lib,
  standalone,
  link,
  namedPackages,
  ...
}:

{
  targets.darwin.copyApps.directory = "Applications/Nix";

  xdg.configFile."aerospace".source = link "aerospace/.config/aerospace";

  home.packages = lib.optionals standalone (namedPackages (import ../darwin/apps.nix));
}
