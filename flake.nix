{
  description = "NixOS flake configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?branch=add-gpg-key";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    secrets = {
      url = "git+ssh://git@github.com/taheris/secrets.git?ref=main&shallow=1";
      flake = false;
    };

    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      plasma-manager,
      solaar,
      sops-nix,
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
                solaar.nixosModules.default
                sops-nix.nixosModules.sops
              ];
            };
          }) linuxHosts
        );

        homeConfigurations = listToAttrs (
          map (host: {
            name = "${host.user}@${host.name}";
            value = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${host.system};
              modules = [
                plasma-manager.homeManagerModules.plasma-manager
                sops-nix.homeManagerModules.sops
                ./home
              ];
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
                    home-manager.sharedModules = [
                      mac-app-util.homeManagerModules.default
                      sops-nix.homeManagerModules.sops
                    ];
                    home-manager.users.${host.user} = import ./home;
                  }
                ];
              };
          }) darwinHosts
        );
      };
    };
}
