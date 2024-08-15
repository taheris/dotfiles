{
  description = "NixOS flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      home-manager,
      ...
    }:

    let
      inherit (self) outputs;

    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-rfc-style;
          packages = import ./nix/pkgs pkgs;
        };

      flake = {
        overlays = import ./nix/overlays { inherit inputs; };
        nixosModules = import ./nix/modules/nixos;
        homeManagerModules = import ./nix/modules/home-manager;

        nixosConfigurations = {
          nix = nixpkgs.lib.nixosSystem {
            modules = [
              ./nix/nixos/configuration.nix
              {
                _module.args = {
                  hostname = "nix";
                };
              }
            ];
            specialArgs = {
              inherit inputs outputs;
            };
          };
        };

        homeConfigurations = {
          "shaun@nix" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            modules = [ ./nix/home-manager/home.nix ];
            extraSpecialArgs = {
              inherit inputs outputs;
            };
          };
        };
      };
    };
}
