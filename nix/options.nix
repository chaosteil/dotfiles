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
  # removeApps. All home modules resolve their package lists with it, so
  # removeApps applies to each list. A name with a "." goes down into an
  # attribute set, for example "luaPackages.luacheck".
  config._module.args.namedPackages =
    names:
    map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) (
      lib.subtractLists config.local.removeApps names
    );

  # A file in ./hosts holds plain data. This is the one place that maps that
  # data onto the options above. A key that the host file does not set keeps
  # the default. The other home modules read only the options.
  config.local = {
    inherit user;
  }
  // lib.optionalAttrs (host ? fullName) { inherit (host) fullName; }
  // lib.optionalAttrs (host ? email) { inherit (host) email; }
  // lib.optionalAttrs (host ? bookmarkPrefix) { inherit (host) bookmarkPrefix; }
  // lib.optionalAttrs (host ? apps) { inherit (host) apps; }
  // lib.optionalAttrs (host ? removeApps) { inherit (host) removeApps; }
  # The nix-darwin module installs Secretive, because the app must be in
  # /Applications. This path is the public key that Secretive writes.
  // lib.optionalAttrs (host ? secretiveKey) {
    signingKey =
      "${config.home.homeDirectory}/Library/Containers"
      + "/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/${host.secretiveKey}.pub";
  };
}
