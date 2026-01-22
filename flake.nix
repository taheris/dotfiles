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
    nixpkgs.url = "git+ssh://git@github.com/nixos/nixpkgs.git?ref=nixpkgs-unstable&shallow=1";
    nixpkgs-stable.url = "git+ssh://git@github.com/nixos/nixpkgs.git?ref=nixos-25.05&shallow=1";

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "git+ssh://git@github.com/hercules-ci/flake-parts.git?ref=main&shallow=1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "git+ssh://git@github.com/nix-community/home-manager.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "git+ssh://git@github.com/LnL7/nix-darwin.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "git+ssh://git@github.com/gmodena/nix-flatpak.git?ref=main&shallow=1";

    secrets = {
      url = "git+ssh://git@github.com/taheris/secrets.git?ref=main&shallow=1";
      flake = false;
    };

    solaar = {
      url = "git+ssh://git@github.com/Svenum/Solaar-Flake.git?ref=main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "git+ssh://git@github.com/Mic92/sops-nix.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrapix = {
      url = "git+ssh://git@github.com/taheris/wrapix.git?ref=main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      dms,
      dms-plugin-registry,
      flake-parts,
      home-manager,
      niri,
      nix-darwin,
      solaar,
      sops-nix,
      stylix,
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
        { system, inputs', ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          wrapix = inputs'.wrapix.legacyPackages.lib;
        in
        {
          formatter = pkgs.nixfmt-tree;
          packages = import ./packages { inherit pkgs; } // {
            default = wrapix.mkSandbox {
              profile = wrapix.profiles.base;
            };
          };
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
                niri.nixosModules.niri
                solaar.nixosModules.default
                sops-nix.nixosModules.sops
                stylix.nixosModules.stylix
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
                dms.homeModules.dank-material-shell
                dms.homeModules.niri
                dms-plugin-registry.modules.default
                niri.homeModules.niri
                sops-nix.homeManagerModules.sops
                stylix.homeModules.stylix
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
                  home-manager.darwinModules.home-manager
                  {
                    home-manager.extraSpecialArgs = specialArgs;
                    home-manager.sharedModules = [
                      sops-nix.homeManagerModules.sops
                      stylix.homeModules.stylix
                    ];
                    home-manager.users.${host.user} = import ./home;
                  }
                  stylix.darwinModules.stylix
                ];
              };
          }) darwinHosts
        );
      };
    };
}
