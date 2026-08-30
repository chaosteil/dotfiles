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
        djmbp4 = "aarch64-darwin";
        macbook = "aarch64-darwin";
        thinkpad = "x86_64-linux";
      };
      perHost = lib.listToAttrs (
        lib.concatMap (
          user:
          lib.mapAttrsToList (
            host: system:
            lib.nameValuePair "${user}@${host}" (mkHome {
              inherit user system;
            })
          ) hosts
        ) users
      );
      fallback = lib.genAttrs users (
        user:
        mkHome {
          inherit user;
          system = defaultSystem;
        }
      );

      mkHome =
        { user, system }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ inputs.rust-overlay.overlays.default ];
          };
          extraSpecialArgs = { inherit inputs user; };

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [ ./home.nix ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      mkDarwin =
        { user, system }:
        inputs.nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs user system; };
          modules = [ ./configuration.nix ];
        };
      darwinHosts = lib.filterAttrs (_: s: lib.hasSuffix "darwin" s) hosts;
    in
    {
      homeConfigurations = perHost // fallback;
      darwinConfigurations = lib.listToAttrs (
        lib.concatMap (
          user:
          lib.mapAttrsToList (
            host: system:
            lib.nameValuePair "${user}@${host}" (mkDarwin {
              inherit user system;
            })
          ) darwinHosts
        ) users
      );

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
