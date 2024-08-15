{ inputs, ... }:

{
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    faiss = inputs.nixpkgs-stable.legacyPackages.${final.system}.faiss;
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  #unstable-packages = final: _prev: {
  #  unstable = import inputs.nixpkgs-unstable {
  #    system = final.system;
  #    config.allowUnfree = true;
  #  };
  #};
}
