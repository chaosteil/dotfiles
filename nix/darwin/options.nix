{
  lib,
  pkgs,
  host,
  ...
}:
let
  nixApps = "/Applications/Nix Apps";
in
{
  options.local = {
    apps = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = map (name: pkgs.${name}) (import ./apps.nix);
      defaultText = lib.literalExpression "map (name: pkgs.\${name}) (import ./apps.nix)";
      description = "The GUI applications that nix-darwin installs.";
    };

    privateAssets = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install the fonts from the private assets repository. Set this
        key only after GitHub has the SSH key of this machine.
      '';
    };

    dockApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "${nixApps}/Firefox.app"
        "${nixApps}/Ghostty.app"
        "${nixApps}/Notion.app"
        "/Applications/Notion Calendar.app"
        "/Applications/Todoist.app"
        "${nixApps}/Spotify.app"
        "/Applications/Discord.app"
        "/System/Applications/iPhone Mirroring.app"
      ];
      description = ''
        The full list of apps in the dock, in order. Each item is an
        absolute path. An app from apps.nix is in "${nixApps}".
      '';
    };
  };

  # A file in ../hosts holds plain data. This is the one place that maps
  # that data onto the options above. A key that the host file does not
  # set keeps the default. The rest of the darwin module reads only the
  # options. The key "removeApps" removes names from the set in apps.nix.
  # The key "apps" adds packages through the home configuration, not
  # here. The key "dockApps" replaces the full dock list. It is a
  # function that gets the path of the Nix apps folder and returns the
  # list.
  config.local =
    lib.optionalAttrs (host ? removeApps) {
      apps = map (name: pkgs.${name}) (lib.subtractLists host.removeApps (import ./apps.nix));
    }
    // lib.optionalAttrs (host ? dockApps) { dockApps = host.dockApps nixApps; }
    // lib.optionalAttrs (host ? privateAssets) { inherit (host) privateAssets; };
}
