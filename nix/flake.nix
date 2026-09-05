{
  # How to use this flake:
  #
  # 1. Install Nix with flakes enabled (https://nixos.org/download).
  #    If flakes are off, add this option to each command:
  #      --extra-experimental-features "nix-command flakes"
  # 2. Configure the machine with one command.
  #    If the machine does not have this repository:
  #      nix run "github:chaosteil/dotfiles?dir=nix"
  #    If ~/dotfiles has this repository already:
  #      nix run ~/dotfiles/nix
  #    The command clones the repository to ~/dotfiles. If the repository
  #    is there already, the command makes it a colocated jujutsu
  #    repository. For a new machine it also writes nix/hosts/<host>.nix.
  #    This can potentially fail due to /etc/bashrc etc. Move them around to
  #    there are backups.
  # 3. The bootstrap contains darwin-rebuild and home-manager. To apply
  #    the configuration without the bootstrap, use these commands:
  #      sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/dotfiles/nix
  #      nix run home-manager/master -- switch --flake ~/dotfiles/nix -b hm-bak
  #    nix reads the flake through git. For a new host file, first run
  #    "git -C ~/dotfiles add nix/hosts/<host>.nix".
  #    If sudo does not find nix, give the full path of the nix command.
  # 4. On first install on OSX you will need to run xcode-select --install as
  #    well as chsh -s /etc/profiles/per-user/$USER/bin/fish
  # 5. Apply later changes from the local repository:
  #      sudo darwin-rebuild switch --flake ~/dotfiles/nix   # macOS
  #      home-manager switch --flake ~/dotfiles/nix          # Linux, or macOS user only
  #    The tools find the correct configuration from $USER and the
  #    hostname. No #attribute is necessary.
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
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
          config.allowUnfree = true;
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
          modules = self.homeModules.${if isDarwin host.system then "darwin" else "linux"}.imports;
        };
      mkDarwin =
        { user, host }:
        inputs.nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs user host; };
          modules = [ ./darwin ];
        };
      darwinHosts = lib.filterAttrs (_: h: isDarwin h.system) hosts;
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
      ) hosts;

      # The name of each attribute is the hostname.
      darwinConfigurations = lib.mapAttrs (
        _: host:
        mkDarwin {
          inherit (host) user;
          inherit host;
        }
      ) darwinHosts;

      packages = forAllSystems (system: {
        bootstrap = import ./bootstrap.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          home-manager = home-manager.packages.${system}.default;
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
