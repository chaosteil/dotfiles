# nixpkgs reads systemd.defaultPath for the PATH of each service. The NixOS
# systemd module declares this option, but system-manager does not load that
# module. Remove this file when system-manager declares the option.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.systemd.defaultPath = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    # The same packages as the NixOS default.
    default = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
      config.systemd.package
    ];
    description = "Packages added to the PATH of all services.";
  };
}
