{ inputs, config, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          config.flake.overlays.packages
          config.flake.overlays.fixes
        ];
        config.allowUnfree = true;
      };
    };
}
