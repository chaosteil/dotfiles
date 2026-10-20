# Overlays for every nixpkgs instance: the standalone home-manager one on Linux
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

  (_final: prev: {
    # The nixpkgs darwin fails if this is included.
    cargo-generate = prev.cargo-generate.overrideAttrs (old: {
      checkFlags = old.checkFlags ++ [ "--skip=utils::tests::should_canonicalize" ];
    });
  })

  (_final: prev: {
    # GKE access
    google-cloud-sdk =
      (prev.google-cloud-sdk.withExtraComponents.override { inherit (prev) google-cloud-sdk; })
        [ prev.google-cloud-sdk.components.gke-gcloud-auth-plugin ];
  })

  # The host EGL platform files name the NVIDIA plugins by soname only. Add
  # /run/opengl-driver/lib to the RUNPATH so that nix programs find them.
  (final: prev: {
    linuxPackages = prev.linuxPackages.extend (
      _lfinal: lprev: {
        nvidiaPackages = lprev.nvidiaPackages // {
          mkDriver =
            args:
            (lprev.nvidiaPackages.mkDriver args).overrideAttrs (old: {
              libPath = old.libPath + ":${final.addDriverRunpath.driverLink}/lib";
            });
        };
      }
    );
  })

  # FHS sandboxes have their own /usr, so the host /etc files that point into
  # /usr do not resolve. Give them the host time zone, fonts, icons and
  # themes, and open links through the portal, outside the sandbox.
  (final: prev: {
    buildFHSEnv =
      args:
      prev.buildFHSEnv (
        finalAttrs:
        let
          attrs = prev.lib.toFunction args finalAttrs;
          # Mount points in the read-only /usr. buildEnv drops empty dirs.
          hostMounts = final.runCommandLocal "fhs-host-mounts" { } ''
            mkdir -p "$out/share/fonts" "$out/share/fontconfig"
            touch "$out/share/fonts/.keep" "$out/share/fontconfig/.keep"
          '';
        in
        attrs
        // {
          targetPkgs =
            pkgs:
            (attrs.targetPkgs or (_: [ ])) pkgs
            ++ [
              pkgs.tzdata
              pkgs.xdg-utils
              hostMounts
            ];
          extraBwrapArgs = (attrs.extraBwrapArgs or [ ]) ++ [
            "--ro-bind-try /usr/share/fonts /usr/share/fonts"
            "--ro-bind-try /usr/share/fontconfig /usr/share/fontconfig"
            "--ro-bind-try /usr/share/icons /.host-share/icons"
            "--ro-bind-try /usr/share/themes /.host-share/themes"
          ];
          profile = (attrs.profile or "") + ''
            export XDG_DATA_DIRS="$XDG_DATA_DIRS:/.host-share"
            export NIXOS_XDG_OPEN_USE_PORTAL=1
          '';
        }
      );
  })

  # Agent hooks report their state to the terminal with it.
  (final: _prev: {
    program-status = final.writeShellApplication {
      name = "program-status";
      runtimeInputs = [
        final.coreutils
        final.perl
        final.ps
      ];
      text = builtins.readFile ../agents/bin/program-status;
    };
    codex-program-status = final.writeShellApplication {
      name = "codex-program-status";
      runtimeInputs = [
        final.jq
        final.program-status
      ];
      text = builtins.readFile ../agents/codex/program-status;
    };
  })

  # Symposium is not in nixpkgs. The version comes from the Cargo.toml of
  # the input, so an update changes only the tag in flake.nix. The upstream
  # tests need a test-agents.toml and the network, so they do not run.
  (final: _prev: {
    symposium = final.rustPlatform.buildRustPackage {
      pname = "symposium";
      inherit ((final.lib.importTOML "${inputs.symposium}/Cargo.toml").package) version;
      src = inputs.symposium;
      cargoLock.lockFile = "${inputs.symposium}/Cargo.lock";
      cargoBuildFlags = [
        "--bin"
        "cargo-agents"
      ];
      doCheck = false;
      meta.mainProgram = "cargo-agents";
    };
  })

  # Fonts from the private repository. The attribute is lazy, so nix
  # fetches the input only for a host that reads this package.
  (final: _prev: {
    private-assets = final.runCommandLocal "private-assets" { } ''
      mkdir -p "$out/share/fonts/truetype"
      cp -r ${inputs.private-assets}/fonts/. "$out/share/fonts/truetype/"
    '';
  })
]
