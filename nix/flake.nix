{
  # How to use this flake:
  #
  # 1. Install Nix with flakes enabled (https://nixos.org/download).
  #    If flakes are off, add this option to each command:
  #      --extra-experimental-features "nix-command flakes"
  # 2. If the machine does not have this repository:
  #      nix run "github:chaosteil/dotfiles?dir=nix"
  #    If ~/dotfiles has this repository already:
  #      nix run ~/dotfiles/nix
  #    The command clones the repository to ~/dotfiles. If the repository
  #    is there already, the command makes it a colocated jujutsu
  #    repository. For a new machine it also writes nix/hosts/<host>.nix.
  #    On macOS, nix-darwin stops when /etc/bashrc or /etc/zshrc is not
  #    its own file. Move the file away and run the command again.
  # 3. The bootstrap contains darwin-rebuild and home-manager. To apply
  #    the configuration without the bootstrap, use these commands:
  #      sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/dotfiles/nix  # macOS
  #      nix run home-manager/master -- switch --flake ~/dotfiles/nix -b hm-bak          # Linux
  #    nix reads the flake through git. A new host file is visible after
  #    a jj snapshot, for example "jj -R ~/dotfiles status".
  # 4. On first install on OSX you will need to run:
  #      xcode-select --install
  #      chsh -s /etc/profiles/per-user/$USER/bin/fish
  #    Secretive key can also fail to read if the terminal doesn't have full
  #    filesystem access. Full Disk Access in OSX Privacy settings.
  # 5. Apply later changes from the local repository:
  #      sudo darwin-rebuild switch --flake ~/dotfiles/nix   # macOS
  #      home-manager switch --flake ~/dotfiles/nix          # Linux
  #    The tools find the correct configuration from $USER and the
  #    hostname. No #attribute is necessary.
  # 6. Linux has a system layer in nix/system/ (like nix-darwin). Apply it
  #    after home-manager, and restart nix-daemon after the first switch:
  #      system-manager switch --flake ~/dotfiles/nix --sudo
  #    A new Arch machine starts with ~/dotfiles/setup/arch-nix/install.sh.
  # 7. After an NVIDIA driver update from pacman, run "nvidia-sync" and
  #    reboot.
  description = "The dotfiles of Dominykas Djacenko";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The package is in overlays.nix. To update, change the tag, then run
    # "nix flake update symposium".
    symposium = {
      url = "github:symposium-dev/symposium/symposium-v0.5.1";
      flake = false;
    };
    # Until the first release, the download needs the token in /etc/nix/netrc.
    # flake.lock records only the release URL.
    # https://www.superlogical.com/rex/docs/linux/installation
    # Rex keeps its own nixpkgs. The release binary crashes with a newer glibc.
    rex.url = "https://pkgs.superlogical.com/rex/nix/snapshot.tar.gz";

    # Agent skills
    skill-simple-english = {
      url = "github:AminBlg/SimpleEnglish/v2.0.0";
      flake = false;
    };
    skill-jujutsu = {
      url = "github:danverbraganza/jujutsu-skill";
      flake = false;
    };
    skill-bevy = {
      url = "github:bfollington/terma";
      flake = false;
    };
    skill-frontend-slides = {
      url = "github:zarazhangrui/frontend-slides";
      flake = false;
    };
    codeview = {
      url = "github:chaosteil/codeview";
      flake = false;
    };

    # Private repository for some custom binary files.
    private-assets = {
      url = "git+ssh://git@github.com/chaosteil/private-assets.git?shallow=1";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      forAllSystems = lib.genAttrs (import ./systems.nix);

      hosts = import ./hosts lib;

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            # For the NVIDIA libraries of the Home Manager GPU module.
            nvidia.acceptLicense = true;
          };
          overlays = import ./overlays.nix inputs;
        };

      isDarwin = system: lib.hasSuffix "darwin" system;

      mkHome =
        { user, host }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs host.system;
          extraSpecialArgs = {
            inherit inputs user host;
            standalone = true;
          };
          modules = self.homeModules.linux.imports;
        };
      mkDarwin =
        { user, host }:
        inputs.nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs user host; };
          modules = [ ./darwin ];
        };
      mkSystem =
        {
          user,
          host,
          hostName,
        }:
        inputs.system-manager.lib.makeSystemConfig {
          # Not nixpkgs.overlays: its "anything" type recurses infinitely.
          overlays = import ./overlays.nix inputs;
          modules = [
            ./system
            {
              nixpkgs = {
                hostPlatform = host.system;
                config.allowUnfree = true;
              };
            }
          ];
          specialArgs = {
            inherit
              inputs
              user
              host
              hostName
              ;
          };
        };
      darwinHosts = lib.filterAttrs (_: h: isDarwin h.system) hosts;
      linuxHosts = lib.filterAttrs (_: h: !isDarwin h.system) hosts;
    in
    {
      homeModules = {
        darwin.imports = [
          ./options.nix
          ./home
          ./home/darwin.nix
        ];
        linux.imports = [
          ./options.nix
          ./home
          ./home/linux.nix
        ];
      };

      # The name of each attribute is "<user>@<hostname>".
      homeConfigurations = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "${host.user}@${name}" (mkHome {
          inherit (host) user;
          inherit host;
        })
      ) linuxHosts;

      # Named by hostname, so system-manager finds them.
      systemConfigs = lib.mapAttrs (
        name: host:
        mkSystem {
          inherit (host) user;
          inherit host;
          hostName = name;
        }
      ) linuxHosts;

      # The name of each attribute is the hostname.
      darwinConfigurations = lib.mapAttrs (
        _: host:
        mkDarwin {
          inherit (host) user;
          inherit host;
        }
      ) darwinHosts;

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # "nix flake check" runs the lints and evaluates every configuration.
      # An evaluation instantiates the derivation. It does not build it,
      # because a build of a whole configuration is too slow for a check.
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          evalCheck =
            name: drv:
            pkgs.runCommandLocal "eval-${name}" {
              drvPath = builtins.unsafeDiscardStringContext drv.drvPath;
            } ''echo "$drvPath" > "$out"'';
        in
        {
          lint =
            pkgs.runCommandLocal "lint"
              {
                nativeBuildInputs = [
                  pkgs.deadnix
                  pkgs.shellcheck
                  pkgs.statix
                ];
              }
              ''
                # The flake is in nix/, so self is that directory.
                cd ${self}/..
                statix check nix
                deadnix --fail nix
                shellcheck agents/claude/hooks/*.sh agents/bin/program-status agents/codex/program-status agents/rex/agent-panes setup/arch-nix/install.sh
                shellcheck --shell=bash nix/scripts/nvidia-sync nix/scripts/lid-awake
                touch "$out"
              '';
        }
        // lib.mapAttrs' (
          name: host:
          lib.nameValuePair "home-${name}" (
            evalCheck "home-${name}" self.homeConfigurations."${host.user}@${name}".activationPackage
          )
        ) linuxHosts
        // lib.mapAttrs' (
          name: _: lib.nameValuePair "system-${name}" (evalCheck "system-${name}" self.systemConfigs.${name})
        ) linuxHosts
        // lib.mapAttrs' (
          name: _:
          lib.nameValuePair "darwin-${name}" (
            evalCheck "darwin-${name}" self.darwinConfigurations.${name}.system
          )
        ) darwinHosts
      );

      packages = forAllSystems (system: {
        bootstrap = import ./bootstrap.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          home-manager = home-manager.packages.${system}.default;
          system-manager = if isDarwin system then null else inputs.system-manager.packages.${system}.default;
          darwin-rebuild =
            if isDarwin system then inputs.nix-darwin.packages.${system}.darwin-rebuild else null;
        };
      });

      apps = forAllSystems (
        system:
        let
          bootstrap = {
            type = "app";
            program = lib.getExe self.packages.${system}.bootstrap;
            meta.description = "Clone the dotfiles and apply the configuration of this machine";
          };
        in
        {
          inherit bootstrap;
          default = bootstrap;
        }
      );
    };
}
