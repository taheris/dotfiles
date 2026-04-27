{
  config,
  lib,
  den,
  ...
}:
let
  nixpkgs = {
    overlays = [
      config.flake.overlays.packages
      config.flake.overlays.fixes
    ];
    config = {
      allowUnfree = true;
      problems.handlers.arrow-cpp.broken = "warn";
    };
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
    homeManager = {
      home.stateVersion = "26.05";
      inherit nixpkgs;
    };

    includes = [
      den.provides.mutual-provider
      den.provides.hostname
      den.provides.define-user
    ];
  };

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
  den.schema.host.options = {
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 13;
      description = "Default font size for terminal/UI on this host.";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "shaun";
      description = "Primary user name for this host.";
    };
    hasLinuxBuilder = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host has access to a Linux remote builder.";
    };
  };
}
