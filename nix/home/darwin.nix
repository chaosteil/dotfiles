{
  link,
  ...
}:

{
  targets.darwin.copyApps.directory = "Applications/Nix";

  xdg.configFile."aerospace".source = link "aerospace/.config/aerospace";
  xdg.configFile."rex".source = link "rex/.config/rex";
}
