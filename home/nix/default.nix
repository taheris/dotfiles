{
  lib,
  pkgs,
  host,
  ...
}:

let
  inherit (lib) mkIf;

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

  nixpkgs = mkIf (host ? isLinux) ({
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    overlays = [
      #outputs.overlays.additions
      #outputs.overlays.modifications
      #outputs.overlays.unstable-packages
    ];
  });
}
