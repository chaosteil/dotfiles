# The Hyprland desktop, for hosts with desktop = "hyprland".
{
  config,
  lib,
  link,
  ...
}:

let
  cursor = config.home.pointerCursor;

  monitors = config.local.monitors;

  # toString writes a float with six decimals (59.950000). Hyprland reads
  # "59.95" and "120".
  hz =
    rate:
    let
      whole = builtins.floor rate;
      cents = builtins.floor ((rate - whole) * 100 + 0.5);
    in
    if cents == 0 then toString whole else "${toString whole}.${lib.fixedWidthNumber 2 cents}";

  monitorRule = m: ''
    hl.monitor({
      output = "${m.output}",
      mode = "${toString m.width}x${toString m.height}@${hz m.refreshRate}Hz",
      position = "${m.position}",
      scale = 1,
    })
  '';

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
      # The monitors of the host file. The file returns the output names,
      # so main.lua reads them with require("01-monitors").
      "01-monitors" =
        lib.concatMapStrings monitorRule monitors
        + "return ${lib.generators.toLua { } (map (m: m.output) monitors)}\n";
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
