{
  lib,
  config,
  options,
  pkgs,
  host,
  ...
}:

{
  options.local = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "User name on this machine";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Dominykas Djacenko";
      description = "The name that git and jj write into commits.";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "chaosteil@gmail.com";
      description = "The email address that git and jj write into commits.";
    };

    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/Users/dominykas/.ssh/id_ed25519.pub";
      description = ''
        The full path of the SSH public key that signs commits. A machine
        with no key does not sign. The module does not expand "~", so
        give an absolute path.
      '';
    };

    bookmarkPrefix = lib.mkOption {
      type = lib.types.str;
      default = config.local.user;
      defaultText = lib.literalExpression "config.local.user";
      description = "The prefix of the jj bookmarks that this account pushes.";
    };

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "The nixpkgs names of extra packages for this machine.";
    };

    removeApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "The nixpkgs names of packages that this machine does not install.";
    };

    privateAssets = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install the fonts from the private assets repository on Linux.
        Set this key only after GitHub has the SSH key of this machine.
        On macOS, nix-darwin installs the fonts.
      '';
    };

    desktop = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "hyprland" ]);
      default = null;
      description = ''
        The desktop that nix installs on this Linux machine. The value null
        means no desktop. More values can come later.
      '';
    };

    cameraLight = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Turn the Logitech Litra Glow light on while a program uses a camera,
        and off when no program uses it. Linux only.
      '';
    };

    nvidia = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            version = lib.mkOption {
              type = lib.types.str;
              description = "The version of the NVIDIA driver that the host has.";
            };
            sha256 = lib.mkOption {
              type = lib.types.str;
              description = "The hash of the NVIDIA installer for this version.";
            };
          };
        }
      );
      default = null;
      description = ''
        The NVIDIA driver of this Linux machine. nix builds the user-space
        libraries of the same version. The value null means no NVIDIA GPU.
      '';
    };

    monitors = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            output = lib.mkOption {
              type = lib.types.str;
              example = "DP-1";
              description = "The connector name of the monitor.";
            };
            width = lib.mkOption {
              type = lib.types.int;
              description = "The width of the mode, in pixels.";
            };
            height = lib.mkOption {
              type = lib.types.int;
              description = "The height of the mode, in pixels.";
            };
            refreshRate = lib.mkOption {
              type = lib.types.number;
              example = 59.95;
              description = "The refresh rate of the mode, in Hz.";
            };
            position = lib.mkOption {
              type = lib.types.str;
              default = "auto";
              example = "2560x-1440";
              description = "The position of the monitor, as Hyprland writes it.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        The monitors of this Linux machine. The first monitor is the
        primary one. hyprland.nix writes the Hyprland monitor rules from
        this list, and system/default.nix writes the greeter output.
      '';
    };
  };

  # The helper turns nixpkgs names into packages and drops the names in
  # removeApps.
  config._module.args.namedPackages =
    names:
    map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) (
      lib.subtractLists config.local.removeApps names
    );

  # The host file holds plain data. Each key with the name of an option
  # above sets that option. The other keys, for example hostUnits, belong
  # to other modules.
  config.local = builtins.intersectAttrs options.local host;
}
