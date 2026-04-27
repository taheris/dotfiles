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
    user = lib.mkOption {
      type = lib.types.str;
      default = "user";
      description = "Primary user name for this host.";
    };

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 14;
      description = "Default font size for terminal/UI on this host.";
    };

    hasLinuxBuilder = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host has access to a remote Nix Linux builder.";
    };
  };
}
