{
  system = "x86_64-linux";
  user = "chaos";
  fullName = "Dominykas Djacenko";
  email = "chaosteil@gmail.com";
  bookmarkPrefix = "chaosteil";
  privateAssets = true;
  desktop = "hyprland";
  nvidia = {
    version = "615.71.09";
    sha256 = "sha256-zc7tIrvrYSSNGm3qvCWWZz46ZQFpjucayNL9wo87cP4=";
  };
  # Matches the monitors in hypr/.config/hypr/main.lua.
  greeterOutput = {
    width = 5120;
    height = 1440;
    refresh_rate = "DP-1:120; HDMI-A-1:60";
  };
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
