{
  lib,
  config,
  pkgs,
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
      example = "/Users/dominykas/.ssh/id_ed25519.pub";
      description = ''
        The full path of the SSH public key that signs commits. A machine
        with no key does not sign. The module does not expand "~", so
        give an absolute path.
      '';
    };

    bookmarkPrefix = lib.mkOption {
      type = lib.types.str;
      default = config.local.user;
      defaultText = lib.literalExpression "config.local.user";
      description = "The prefix of the jj bookmarks that this account pushes.";
    };

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "The nixpkgs names of extra packages for this machine.";
    };

    removeApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "The nixpkgs names of packages that this machine does not install.";
    };
  };

  # The helper turns nixpkgs names into packages and drops the names in
  # removeApps.
  config._module.args.namedPackages =
    names:
    map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) (
      lib.subtractLists config.local.removeApps names
    );

  config.local = {
    inherit user;
  }
  // lib.optionalAttrs (host ? fullName) { inherit (host) fullName; }
  // lib.optionalAttrs (host ? email) { inherit (host) email; }
  // lib.optionalAttrs (host ? bookmarkPrefix) { inherit (host) bookmarkPrefix; }
  // lib.optionalAttrs (host ? apps) { inherit (host) apps; }
  // lib.optionalAttrs (host ? removeApps) { inherit (host) removeApps; }
  // lib.optionalAttrs (host ? signingKey) { inherit (host) signingKey; };
}
