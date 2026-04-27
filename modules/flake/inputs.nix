{ ... }:
{
  flake-file = {
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
  };

  flake-file.inputs = {
    nixpkgs.url = "git+ssh://git@github.com/nixos/nixpkgs.git?ref=nixpkgs-unstable&shallow=1";
    nixpkgs-stable.url = "git+ssh://git@github.com/nixos/nixpkgs.git?ref=nixos-25.05&shallow=1";
    nixpkgs-lib.follows = "nixpkgs";

    den.url = "git+ssh://git@github.com/denful/den.git?shallow=1";
    flake-file.url = "git+ssh://git@github.com/vic/flake-file.git?shallow=1";
    import-tree.url = "git+ssh://git@github.com/vic/import-tree.git?shallow=1";

    flake-parts = {
      url = "git+ssh://git@github.com/hercules-ci/flake-parts.git?ref=main&shallow=1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "git+ssh://git@github.com/nix-community/home-manager.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "git+ssh://git@github.com/LnL7/nix-darwin.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "git+ssh://git@github.com/sodiboo/niri-flake.git?ref=main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "git+ssh://git@github.com/gmodena/nix-flatpak.git?ref=main&shallow=1";

    sops-nix = {
      url = "git+ssh://git@github.com/Mic92/sops-nix.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "git+ssh://git@github.com/nix-community/stylix.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/taheris/secrets.git?ref=main&shallow=1";
      flake = false;
    };

    wrapix = {
      url = "git+ssh://git@github.com/taheris/wrapix.git?ref=main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    dms = {
      url = "git+ssh://git@github.com/AvengeMedia/DankMaterialShell.git?ref=stable&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "git+ssh://git@github.com/AvengeMedia/dms-plugin-registry.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
