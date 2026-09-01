# One file for each machine. The keys "system" and "user" are necessary. A
# file can also set "fullName", "email", "bookmarkPrefix", and
# "secretiveKey". These override the defaults in ../options.nix.
# A file can also set "apps" and "removeApps". The key "apps" adds
# package names from nixpkgs to the common set in ../home/packages.nix.
# The key "removeApps" removes package names from all of the package
# lists: the common set, the darwin apps, and the linux apps.
# A darwin file can also set "dockApps". This key replaces the full
# dock list. Its value is a function. The function gets the path of the
# folder that holds the apps from Nix, and returns absolute paths:
#   dockApps = nixApps: [ "${nixApps}/Firefox.app" "/Applications/Foo.app" ];
# Each .nix file in this directory becomes a host with the name of the
# file. The bootstrap app writes a new host file for an unknown
# machine, so this list must stay automatic.
lib:
lib.mapAttrs'
  (name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (import (./. + "/${name}")))
  (
    lib.filterAttrs (
      name: type: type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name
    ) (builtins.readDir ./.)
  )
