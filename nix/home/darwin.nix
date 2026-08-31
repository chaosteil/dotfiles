{
  config,
  lib,
  host,
  ...
}:

let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
in
{
  local.signingKey = lib.mkIf (host ? secretiveKey) (
    "${config.home.homeDirectory}/Library/Containers"
    + "/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/${host.secretiveKey}.pub"
  );

  xdg.configFile."aerospace".source = link "aerospace/.config/aerospace";
}
