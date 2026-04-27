{ config, lib, ... }:
let
  nixpkgs = {
    overlays = [
      config.flake.overlays.packages
      config.flake.overlays.fixes
    ];
    config.allowUnfree = true;
  };
in
{
  den.default = {
    nixos = {
      system.stateVersion = "24.11";
      inherit nixpkgs;
    };
    darwin = {
      system.stateVersion = 6;
      inherit nixpkgs;
    };
    homeManager.home.stateVersion = "26.05";
  };

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
  den.schema.host.options.fontSize = lib.mkOption {
    type = lib.types.int;
    default = 13;
    description = "Default font size for terminal/UI on this host.";
  };
}
