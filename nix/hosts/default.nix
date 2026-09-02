# One file for each machine. The keys "system" and "user" are necessary.
# Each .nix file in this directory becomes a host with the name of the
# file. The bootstrap app writes a new host file for an unknown
# machine.
lib:
lib.mapAttrs'
  (name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (import (./. + "/${name}")))
  (
    lib.filterAttrs (
      name: type: type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name
    ) (builtins.readDir ./.)
  )
