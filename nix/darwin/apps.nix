pkgs:

with pkgs; [
  aerospace
  blender
  # The firefox-bin wrapper replaces Contents/MacOS/firefox with a shell script.
  # That change removes the Mozilla code signature and the entitlement
  # com.apple.developer.web-browser.public-key-credential. Firefox then cannot use
  # the passkeys of macOS. The unwrapped package keeps the signature.
  firefox-bin-unwrapped
  ghostty-bin
  godot
  google-chrome
  ice-bar
  jankyborders
  libreoffice-bin
  linear
  notion-app
  openscad-unstable
  rectangle
  scroll-reverser
  spotify
  zoom-us
]
