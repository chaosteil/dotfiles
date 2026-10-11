# The system layer of a Linux host, applied as root by system-manager.
{
  inputs,
  lib,
  pkgs,
  user,
  host,
  hostName,
  ...
}:

let
  enableHostUnits = import ./host-units.nix lib;

  # Host files add more with hostUnits.
  commonUnits = [
    {
      unit = "nix-daemon.service";
      wantedBy = "multi-user.target";
    }
    {
      unit = "systemd-timesyncd.service";
      wantedBy = "sysinit.target";
      alias = [ "dbus-org.freedesktop.timesync1.service" ];
    }
    {
      unit = "fstrim.timer";
      wantedBy = "timers.target";
    }
    {
      unit = "nftables.service";
      wantedBy = "multi-user.target";
    }
  ];

  hyprlandSession = pkgs.writeText "hyprland-nix.desktop" ''
    [Desktop Entry]
    Name=Hyprland (nix)
    Exec=/home/${user}/.nix-profile/bin/start-hyprland
    DesktopNames=Hyprland
    Type=Application
  '';
in
{
  system-manager.allowAnyDistro = true;

  # Keep the host in charge of users, mount, PATH and system packages.
  services.userborn.enable = false;
  security.wrappers.mount.enable = false;
  security.wrappers.umount.enable = false;
  environment.etc."profile.d/system-manager-path.sh".enable = false;
  environment.etc."environment.d/10-system-manager.conf".enable = false;
  systemd.services.system-manager-path.enable = lib.mkForce false;
  system-manager.linkCurrentSystem = false;

  # Drop the reference to the disabled userborn.service. Upstream uses mkForce.
  systemd.services.suid-sgid-wrappers.after = lib.mkOverride 40 [ "run-wrappers.mount" ];

  # Link the GPU drivers that Home Manager builds.
  systemd.tmpfiles.settings."10-gpu"."/run/opengl-driver"."L+".argument =
    "${inputs.self.homeConfigurations."${user}@${hostName}".config.targets.genericLinux.gpu.drivers}";

  # nixpkgs PAM (the lock screen) calls this path.
  security.wrappers.unix_chkpwd = {
    setuid = true;
    owner = "root";
    group = "root";
    source = "${pkgs.pam}/bin/unix_chkpwd";
  };

  systemd.tmpfiles.settings."10-session" = lib.mkIf ((host.desktop or null) == "hyprland") {
    "/usr/share/wayland-sessions/hyprland-nix.desktop"."L+".argument = "${hyprlandSession}";
  };

  systemd.tmpfiles.settings."20-units" = enableHostUnits (commonUnits ++ (host.hostUnits or [ ]));

  # Not the nix module: Arch owns the nix package and the daemon.
  # warn-dirty is off, because jj keeps the git tree dirty.
  environment.etc."nix/nix.conf" = {
    text = ''
      build-users-group = nixbld
      experimental-features = nix-command flakes
      auto-optimise-store = true
      max-jobs = auto
      warn-dirty = false
    '';
    replaceExisting = true;
  };

  environment.etc."nftables.conf" = {
    text = builtins.readFile ./nftables.conf;
    replaceExisting = true;
  };
}
