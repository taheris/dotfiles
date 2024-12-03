{
  description = "NixOS flake configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://cache.garnix.io"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

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

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?branch=add-gpg-key";

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      home-manager,
      mac-app-util,
      nix-darwin,
      ...
    }:

    let
      inherit (self) outputs;
      inherit (builtins)
        catAttrs
        filter
        listToAttrs
        ;

      hosts = import ./hosts.nix;
      linuxHosts = filter (host: host.system == "x86_64-linux") hosts;
      darwinHosts = filter (host: host.system == "aarch64-darwin") hosts;

    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = catAttrs "system" hosts;

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-rfc-style;
          packages = import ./packages { inherit pkgs; };
        };

      flake = {
        overlays = import ./overlays { inherit inputs; };
        nixosModules = import ./modules/nixos;
        homeManagerModules = import ./modules/home;

        nixosConfigurations = listToAttrs (
          map (host: {
            name = host.name;
            value = nixpkgs.lib.nixosSystem {
              specialArgs = {
                inherit inputs outputs host;
              };
              system = host.system;
              modules = [
                ./nixos/configuration.nix
              ];
            };
          }) linuxHosts
        );

        homeConfigurations = listToAttrs (
          map (host: {
            name = "${host.user}@${host.name}";
            value = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${host.system};
              modules = [ ./home/home.nix ];
              extraSpecialArgs = {
                inherit inputs outputs host;
              };
            };
          }) linuxHosts
        );

        darwinConfigurations = listToAttrs (
          map (host: {
            name = host.name;
            value =
              let
                specialArgs = {
                  inherit inputs outputs host;
                };
              in
              nix-darwin.lib.darwinSystem {
                inherit specialArgs;
                modules = [
                  ./darwin/configuration.nix
                  mac-app-util.darwinModules.default
                  home-manager.darwinModules.home-manager
                  {
                    home-manager.extraSpecialArgs = specialArgs;
                    home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
                    home-manager.users.${host.user} = import ./home/home.nix;
                  }
                ];
              };
          }) darwinHosts
        );
      };
    };
}
