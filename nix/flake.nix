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
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      forAllSystems = lib.genAttrs (import ./systems.nix);

      users = import ./users.nix;
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

      fallbacks =
        mk: system:
        lib.genAttrs users (
          user:
          mk {
            inherit user;
            host = { inherit system; };
          }
        );

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
      homeConfigurations =
        lib.mapAttrs' (
          name: host:
          lib.nameValuePair "${host.user}@${name}" (mkHome {
            inherit (host) user;
            inherit host;
          })
        ) hosts
        // fallbacks mkHome "x86_64-linux";

      # The name of each attribute is the hostname.
      darwinConfigurations =
        lib.mapAttrs (
          _: host:
          mkDarwin {
            inherit (host) user;
            inherit host;
          }
        ) darwinHosts
        // fallbacks mkDarwin "aarch64-darwin";

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
