{ inputs, ... }:

{
  additions =
    final: _prev:
    import ../packages {
      inherit inputs;
      pkgs = final;
    };

  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
