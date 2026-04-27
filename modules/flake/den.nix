{
  config,
  inputs,
  lib,
  den,
  my,
  ...
}:

let
  inherit (lib) mkDefault;

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
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
    (inputs.den.namespace "my" false)
  ];

  den.default = {
    nixos = {
      system.stateVersion = "24.11";
      inherit nixpkgs;
    };

    homeManager = {
      home.stateVersion = "26.05";
      inherit nixpkgs;
    };

    darwin = {
      system.stateVersion = 6;
      inherit nixpkgs;
    };

    includes = [
      den.provides.define-user
      den.provides.host-aspects
      den.provides.hostname
      den.provides.mutual-provider
      my.host
    ];
  };

  den.schema.user.classes = mkDefault [ "homeManager" ];
}
