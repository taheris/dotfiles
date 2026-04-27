# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "NixOS flake configuration";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

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
    darwin = {
      url = "git+ssh://git@github.com/LnL7/nix-darwin.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    den.url = "git+ssh://git@github.com/denful/den.git?shallow=1";
    dms = {
      url = "git+ssh://git@github.com/AvengeMedia/DankMaterialShell.git?ref=stable&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "git+ssh://git@github.com/AvengeMedia/dms-plugin-registry.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "git+ssh://git@github.com/vic/flake-file.git?shallow=1";
    flake-parts = {
      url = "git+ssh://git@github.com/hercules-ci/flake-parts.git?ref=main&shallow=1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager = {
      url = "git+ssh://git@github.com/nix-community/home-manager.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "git+ssh://git@github.com/vic/import-tree.git?shallow=1";
    niri = {
      url = "git+ssh://git@github.com/sodiboo/niri-flake.git?ref=main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "git+ssh://git@github.com/gmodena/nix-flatpak.git?ref=main&shallow=1";
    nixpkgs.url = "git+ssh://git@github.com/nixos/nixpkgs.git?ref=nixpkgs-unstable&shallow=1";
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-stable.url = "git+ssh://git@github.com/nixos/nixpkgs.git?ref=nixos-25.11&shallow=1";
    secrets = {
      url = "git+ssh://git@github.com/taheris/secrets.git?ref=main&shallow=1";
      flake = false;
    };
    sops-nix = {
      url = "git+ssh://git@github.com/Mic92/sops-nix.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "git+ssh://git@github.com/nix-community/stylix.git?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrapix = {
      url = "git+ssh://git@github.com/taheris/wrapix.git?ref=main&shallow=1";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
}
