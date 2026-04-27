{ inputs, config, ... }:

{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          config.flake.overlays.fixes
          config.flake.overlays.packages
        ];
        config.allowUnfree = true;
      };
    };
}
