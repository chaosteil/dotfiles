{
  description = "Home Manager configuration of dominykas";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
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
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      lib = nixpkgs.lib;

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      defaultSystem = "x86_64-linux";
      forAllSystems = lib.genAttrs systems;

      users = [
        "dominykas"
        "djacenko"
        "dom"
        "chaosteil"
      ];
      hosts = {
        djmbp4 = {
          system = "aarch64-darwin";
          secretiveKey = "2b9168b223b51d053a4987a58092b3b6";
        };
        macbook = {
          system = "aarch64-darwin";
        };
        thinkpad = {
          system = "x86_64-linux";
        };
      };
      fallbackHosts = {
        darwin = {
          system = "aarch64-darwin";
        };
        linux = {
          system = "x86_64-linux";
        };
      };

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ inputs.rust-overlay.overlays.default ];
        };

      isDarwin = system: lib.hasSuffix "darwin" system;

      mkHome =
        { user, host }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs host.system;
          extraSpecialArgs = { inherit inputs user host; };

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
            ./options.nix
            ./home
            (if isDarwin host.system then ./home/darwin.nix else ./home/linux.nix)
          ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      mkDarwin =
        { user, host }:
        inputs.nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs user host; };
          modules = [ ./darwin ];
        };
      darwinHosts = lib.filterAttrs (_: h: isDarwin h.system) hosts;

      # "<user>@<host>" for every combination of a user and a host.
      cross =
        mk: hostSet:
        lib.listToAttrs (
          lib.concatMap (
            user:
            lib.mapAttrsToList (
              name: host:
              lib.nameValuePair "${user}@${name}" (mk {
                inherit user host;
              })
            ) hostSet
          ) users
        );

      # "<user>" alone, for a machine that is not in the host table.
      fallback = mk: host: lib.genAttrs users (user: mk { inherit user host; });

    in
    {
      homeConfigurations = cross mkHome hosts // fallback mkHome fallbackHosts.linux;
      darwinConfigurations = cross mkDarwin darwinHosts // fallback mkDarwin fallbackHosts.darwin;

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          bootstrap = {
            type = "app";
            program = "${pkgs.writeShellScript "bootstrap" ''
              set -euo pipefail
              if [ ! -d "$HOME/dotfiles" ]; then
                git clone https://github.com/chaosteil/dotfiles.git "$HOME/dotfiles"
              fi
              ${home-manager.packages.${system}.default}/bin/home-manager switch \
              --flake github:chaosteil/dotfiles?dir=nix/.config/home-manager -b bak "$@"
            ''}";
          };
        }
      );
    };
}
