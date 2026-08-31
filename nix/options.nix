{ lib, config, ... }:

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
}
