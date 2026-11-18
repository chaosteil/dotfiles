{
  link,
  ...
}:

{
  targets.darwin.copyApps.directory = "Applications/Nix";

  xdg.configFile."aerospace".source = link "aerospace/.config/aerospace";
}
