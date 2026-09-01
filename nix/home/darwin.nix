{
  config,
  lib,
  pkgs,
  host,
  standalone,
  ...
}:

let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
in
{
  # The nix-darwin module installs Secretive, because the app must be in
  # /Applications. This path is the public key that Secretive writes.
  local.signingKey = lib.mkIf (host ? secretiveKey) (
    "${config.home.homeDirectory}/Library/Containers"
    + "/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/${host.secretiveKey}.pub"
  );

  targets.darwin.copyApps.directory = "Applications/Nix";

  xdg.configFile."aerospace".source = link "aerospace/.config/aerospace";

  # Under nix-darwin the system installs these apps into /Applications.
  home.packages = lib.optionals standalone (import ../apps.nix pkgs);
}
