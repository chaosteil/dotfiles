{
  lib,
  config,
  user,
  host,
  ...
}:

{
  options.local = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "User name on this machine";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Dominykas Djacenko";
      description = "The name that git and jj write into commits.";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "chaosteil@gmail.com";
      description = "The email address that git and jj write into commits.";
    };

    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "deadbeef";
      description = ''
        Name of the SSH public key that signs commits.
      '';
    };

    bookmarkPrefix = lib.mkOption {
      type = lib.types.str;
      default = config.local.user;
      defaultText = lib.literalExpression "config.local.user";
      description = "The prefix of the jj bookmarks that this account pushes.";
    };
  };

  # A file in ./hosts holds plain data. This is the one place that maps that
  # data onto the options above. The other home modules read only the options.
  config.local = {
    inherit user;

    # The nix-darwin module installs Secretive, because the app must be in
    # /Applications. This path is the public key that Secretive writes.
    signingKey = lib.mkIf (host ? secretiveKey) (
      "${config.home.homeDirectory}/Library/Containers"
      + "/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/${host.secretiveKey}.pub"
    );
  };
}
