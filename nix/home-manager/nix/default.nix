{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cachix
    devenv
    manix
    nix-direnv-flakes
    nix-index
    nix-output-monitor
    nix-tree
    nixfmt-rfc-style
  ];

  nixpkgs = {
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
