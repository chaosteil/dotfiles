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
    # mold builds no mold-wrapper.so on macOS, but the nixpkgs postInstall moves it.
    mold-unwrapped = prev.mold-unwrapped.overrideAttrs (
      old:
      prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
        postInstall =
          builtins.replaceStrings
            [ "mkdir -p $out/lib/mold\n" "mv $out/lib/mold-wrapper.so $out/lib/mold\n" ]
            [ "" "" ]
            old.postInstall;
      }
    );
  })

  (_final: prev: {
    # The nixpkgs cargo setup hook tells the aws-lc-sys and zstd-sys crates to
    # use the system libraries. The build stops when these crates find no
    # system library. On Linux, the openssl-sys crate also needs the system
    # OpenSSL. The nixpkgs package of proto does not supply them yet.
    # Remove this patch when the nixpkgs package has them in its buildInputs.
    proto = prev.proto.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [
        prev.aws-lc
        prev.openssl
        prev.zstd
      ];
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

  # The NVENC encoders of OBS start obs-nvenc-test to find the GPU. nixpkgs
  # adds /run/opengl-driver/lib to the RUNPATH of the OBS libraries and
  # plugins, but not of this program. Without it, the program does not find
  # libnvidia-encode.so.1, and OBS shows no NVENC encoders.
  (_final: prev: {
    obs-studio = prev.obs-studio.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        addDriverRunpath $out/bin/.obs-nvenc-test-wrapped
      '';
    });
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

  # Agent hooks use these tools. program-status reports the state of an agent
  # to the terminal. agent-neighbours lists the other agents in a repository.
  # agent-panes keeps the Rex layout of an agent.
  # codeview-zoom lets a codeview review fill the Rex window. rex-diagram
  # draws a diagram and shows it in a Rex pane beside the agent. jj and git
  # come from the PATH. rex comes from REX_BIN_DIR, else from the PATH.
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
    agent-neighbours = final.writeShellApplication {
      name = "agent-neighbours";
      runtimeInputs = [
        final.coreutils
        final.jq
        final.lsof
        final.ps
      ];
      text = builtins.readFile ../agents/bin/agent-neighbours;
    };
    codex-session-start = final.writeShellApplication {
      name = "codex-session-start";
      runtimeInputs = [ final.agent-neighbours ];
      text = builtins.readFile ../agents/codex/session-start;
    };
    codex-program-status = final.writeShellApplication {
      name = "codex-program-status";
      runtimeInputs = [
        final.jq
        final.program-status
      ];
      text = builtins.readFile ../agents/codex/program-status;
    };
    agent-panes = final.writeShellApplication {
      name = "agent-panes";
      # The script reads a state file that does not exist on the first run,
      # and it continues after that read. The errexit default of
      # writeShellApplication stops the script there, so the hook writes no
      # state and opens no pane. Keep only the two options that the script
      # sets itself.
      bashOptions = [
        "nounset"
        "pipefail"
      ];
      runtimeInputs = [
        final.coreutils
        final.flock
        final.jq
      ];
      runtimeEnv.AGENT_PANES_LUA = ../agents/rex/agent-panes.lua;
      text = builtins.readFile ../agents/rex/agent-panes;
    };
    codeview-zoom = final.writeShellApplication {
      name = "codeview-zoom";
      runtimeInputs = [
        final.coreutils
        final.jq
      ];
      text = builtins.readFile ../agents/rex/codeview-zoom;
    };
    rex-diagram = final.writeShellApplication {
      name = "rex-diagram";
      runtimeInputs = [
        final.coreutils
        final.nodejs
        final.librsvg
        final.python3
      ];
      runtimeEnv = {
        ROUGH_JS = "${
          final.fetchzip {
            url = "https://registry.npmjs.org/roughjs/-/roughjs-4.6.6.tgz";
            hash = "sha256-OUXgHn+PGBQFQUMx2/QrFKYGmuF9shddpgaiMMsoJOI=";
          }
        }/bundled/rough.cjs.js";
        FONTCONFIG_FILE = final.makeFontsConf { fontDirectories = [ final.excalifont ]; };
        REX_DIAGRAM_RENDER = ../agents/rex/rex-diagram-render.cjs;
        REX_DIAGRAM_VIEW = ../agents/rex/rex-diagram-view.py;
      };
      text = builtins.readFile ../agents/rex/rex-diagram;
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

  # pr-agent is not in nixpkgs. chaoshub runs it from the PATH. The ask tool of
  # chaoshub reads the Python from the shebang of bin/pr-agent, so bin/pr-agent
  # is a Python script and not a wrapper. The upstream pins are exact, and
  # nixpkgs has close versions, so the build relaxes all pins. Only the GitHub
  # provider is in. To update, change the version and the hash.
  (final: _prev: {
    pr-agent =
      let
        ps = final.python3Packages;
        lib = ps.buildPythonPackage rec {
          pname = "pr-agent";
          version = "0.49.0";
          pyproject = true;
          src = ps.fetchPypi {
            pname = "pr_agent";
            inherit version;
            hash = "sha256-WXcY5xwOqo7HkiEzoQZM36DNn/UTTCwlSKHiuzl6Hac=";
          };
          build-system = [ ps.setuptools ];
          dependencies = with ps; [
            aiohttp
            anthropic
            certifi
            dynaconf
            fastapi
            gitpython
            gunicorn
            html2text
            jinja2
            langfuse
            litellm
            loguru
            openai
            opentelemetry-api
            opentelemetry-exporter-otlp-proto-http
            opentelemetry-sdk
            prometheus-client
            pydantic
            pydantic-settings
            pygithub
            pyjwt
            pyyaml
            retry
            starlette
            starlette-context
            tenacity
            tiktoken
            ujson
            unidiff
            urllib3
            uvicorn
          ];
          pythonRelaxDeps = true;
          pythonImportsCheck = [
            "pr_agent.cli"
            "pr_agent.git_providers.github_provider"
          ];
        };
        env = final.python3.withPackages (_: [ lib ]);
      in
      final.writeTextFile {
        name = "pr-agent-${lib.version}";
        destination = "/bin/pr-agent";
        executable = true;
        text = ''
          #!${env}/bin/python3
          import sys
          from pr_agent.cli import run
          sys.exit(run())
        '';
        meta.mainProgram = "pr-agent";
      };
  })

  # SolidCraft is not in nixpkgs. The wrapper runs the upstream AppImage in an
  # FHS sandbox. The desktop file and the icons come from the AppImage. All
  # Linux hosts are x86_64, so only that AppImage is here. To update, change
  # the version and the hash. The hash is in SHA256SUMS.txt of the release.
  (final: _prev: {
    solidcraft =
      let
        pname = "solidcraft";
        version = "0.27.0";
        src = final.fetchurl {
          url = "https://github.com/tangency-labs/solidcraft/releases/download/v${version}/solidcraft-${version}-linux-x86_64.AppImage";
          hash = "sha256-HwzI9p4POsyXip434tCCXMqi5N/boXFoGJDqA7NjNyw=";
        };
        contents = final.appimageTools.extract { inherit pname version src; };
      in
      final.appimageTools.wrapType2 {
        inherit pname version src;
        extraInstallCommands = ''
          cp -r ${contents}/usr/share $out/share
        '';
        meta.mainProgram = "solidcraft";
      };
  })

  # CurseForge is not in nixpkgs. The wrapper runs the upstream AppImage in
  # an FHS sandbox, like SolidCraft. The desktop file starts AppRun, so the
  # wrapper points it at the wrapped program. The desktop file also makes
  # CurseForge the handler of the curseforge:// links of the website. The
  # app cannot update itself in the nix store. To update, change the
  # version and the hash. The version is in the macOS URL of
  # https://formulae.brew.sh/cask/curseforge.
  (final: _prev: {
    curseforge =
      let
        pname = "curseforge";
        version = "1.326.0-42377";
        src = final.fetchurl {
          url = "https://curseforge.overwolf.com/electron/linux/CurseForge-${version}.AppImage";
          hash = "sha256-hy0GpwDqKi3ujEdA1aBRA/DBbHyWn1jMoiw2TErBAjo=";
        };
        contents = final.appimageTools.extract { inherit pname version src; };
      in
      final.appimageTools.wrapType2 {
        inherit pname version src;
        extraInstallCommands = ''
          install -Dm444 ${contents}/curseforge.desktop $out/share/applications/curseforge.desktop
          substituteInPlace $out/share/applications/curseforge.desktop \
            --replace-fail "Exec=AppRun" "Exec=curseforge"
          cp -r ${contents}/usr/share/icons $out/share/icons
        '';
        meta.mainProgram = "curseforge";
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
