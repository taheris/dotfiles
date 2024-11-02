{ lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;

in
{
  home.packages = with pkgs; [
    cachix
    devenv
    manix
    nix-direnv-flakes
    nix-index
    nix-output-monitor
    nix-tree
    nixd
    nixfmt-rfc-style
  ];

  nixpkgs = mkIf isLinux {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    overlays = [
      #outputs.overlays.additions
      #outputs.overlays.modifications
      #outputs.overlays.unstable-packages
    ];
  };
}
