# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'

pkgs: {
  monaco = pkgs.callPackage ./monaco { };
  monacob = pkgs.callPackage ./monacob { };
  #monolisa = pkgs.callPackage ./monolisa { };
}
