{ link, namedPackages, ... }:

{
  targets.genericLinux.enable = true;

  # Buncha desktop apps
  home.packages = namedPackages [
    "blender"
    "firefox-bin"
    "ghostty"
    "godot"
    "google-chrome"
    "openscad-unstable"
    "spotify"
    "zoom-us"
  ];

  xdg.configFile."i3".source = link "i3/.config/i3";
}
