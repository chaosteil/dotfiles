# Overlays for every nixpkgs instance: the standalone home-manager one
# (mkPkgs in the flake) and the nix-darwin one.
inputs: [
  inputs.rust-overlay.overlays.default

  # These apps keep the code signature of the vendor. macOS refuses to open an
  # app when the bundle does not agree with that signature. Each patch below
  # removes a change that the nixpkgs build makes to a signed file.
  (_final: prev: {
    # The DMG holds a resource fork on Resources/IntroShot.png. The unpack step
    # writes that fork to a separate "._IntroShot.png" file. This file is not
    # in the sealed manifest, so macOS reports "the app is damaged".
    scroll-reverser = prev.scroll-reverser.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        find "$out/Applications" -name '._*' -delete
      '';
    });

    # The fixup step writes nix store paths to the shebang lines of the shipped
    # scripts, for example Resources/senddoc and the Python framework. macOS
    # sees the new contents of these sealed files and refuses to open the app.
    libreoffice-bin = prev.libreoffice-bin.overrideAttrs (_: {
      dontPatchShebangs = true;
    });
  })
]
