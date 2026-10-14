# Turns the Litra Glow light on while a program uses a camera, for hosts with
# cameraLight = true. See scripts/camera-light.py.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cameraLight = pkgs.writers.writePython3Bin "camera-light" {
    libraries = [ pkgs.python3Packages.inotify-simple ];
  } (builtins.readFile ../scripts/camera-light.py);
in
lib.mkIf config.local.cameraLight {
  # The udev rule "uaccess" of systemd gives the user access to the light.
  systemd.user.services.camera-light = {
    Unit.Description = "Turn the Litra light on while a camera is in use";
    Service = {
      ExecStart = lib.getExe cameraLight;
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
