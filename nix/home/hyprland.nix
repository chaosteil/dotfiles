# The Hyprland desktop, for hosts with desktop = "hyprland".
{
  config,
  lib,
  link,
  ...
}:

let
  cursor = config.home.pointerCursor;

  env = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  }
  // lib.optionalAttrs cursor.enable {
    XCURSOR_THEME = cursor.name;
    XCURSOR_SIZE = toString cursor.size;
    HYPRCURSOR_SIZE = toString cursor.size;
  }
  # See https://wiki.hypr.land/Nvidia/
  // lib.optionalAttrs (config.local.nvidia != null) {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };
in
lib.mkIf (config.local.desktop == "hyprland") {
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    # The portals come from the host.
    portalPackage = null;
    systemd.variables = [ "--all" ];

    # Loaded in name order.
    extraLuaFiles = {
      "00-env" = lib.concatLines (
        lib.mapAttrsToList (name: value: ''hl.env("${name}", "${value}")'') env
      );
      main = link "hypr/.config/hypr/main.lua";
    };
  };

  xdg.configFile."xdg-desktop-portal/hyprland-portals.conf".text = ''
    [preferred]
    default=hyprland;gtk
  '';

  # GUI changes go to ~/.local/state/noctalia/settings.toml, which wins.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
  };

  # The official tray icon of Tailscale, from the tailscale CLI.
  services.tailscale-systray.enable = true;

  # Navy glass to match the bar. Merges with local.conf from linux.nix.
  xdg.configFile."ghostty/local.conf".text = ''
    background = #05041a
    background-opacity = 0.85
  '';

  xdg.configFile."noctalia/config.toml".source = link "noctalia/.config/noctalia/config.toml";
  xdg.configFile."noctalia/palettes".source = link "noctalia/.config/noctalia/palettes";
  xdg.configFile."noctalia/icons".source = link "noctalia/.config/noctalia/icons";
}
