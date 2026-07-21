{ ... }:

{
  my.r8152.nixos =
    { config, pkgs, ... }:
    let
      driver = pkgs.r8152.override {
        kernel = config.boot.kernelPackages.kernel;
      };
    in
    {
      boot = {
        extraModulePackages = [ driver ];
        kernelModules = [ "r8152" ];
      };

      services.udev.packages = [ driver ];
    };
}
