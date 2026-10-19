{
  system = "x86_64-linux";
  user = "chaos";
  fullName = "Dominykas Djacenko";
  email = "chaosteil@gmail.com";
  bookmarkPrefix = "chaosteil";
  privateAssets = true;
  desktop = "hyprland";
  cameraLight = true;
  nvidia = {
    version = "615.78.08";
    sha256 = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
  };
  # The first monitor is the primary one.
  monitors = [
    {
      output = "DP-1";
      width = 5120;
      height = 1440;
      refreshRate = 120;
      position = "0x0";
    }
    {
      output = "HDMI-A-1";
      width = 2560;
      height = 1440;
      refreshRate = 59.95;
      position = "2560x-1440";
    }
  ];
  hostUnits = [
    {
      unit = "bluetooth.service";
      wantedBy = "bluetooth.target";
      alias = [ "dbus-org.bluez.service" ];
    }
    {
      unit = "greetd.service";
      alias = [ "display-manager.service" ];
    }
    {
      unit = "NetworkManager.service";
      wantedBy = "multi-user.target";
    }
    {
      unit = "NetworkManager-dispatcher.service";
      alias = [ "dbus-org.freedesktop.nm-dispatcher.service" ];
    }
    {
      unit = "NetworkManager-wait-online.service";
      wantedBy = "network-online.target";
    }
    {
      unit = "systemd-boot-update.service";
      wantedBy = "sysinit.target";
    }
    # From pacman-contrib.
    {
      unit = "paccache.timer";
      wantedBy = "timers.target";
    }
  ];
}
