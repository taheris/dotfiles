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
      permittedInsecurePackages = [
        "librewolf-151.0.2-1"
        "librewolf-unwrapped-151.0.2-1"
      ];
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
      den.batteries.define-user
      den.batteries.host-aspects
      den.batteries.hostname
      my.host
    ];
  };

  den.schema.user.classes = mkDefault [ "homeManager" ];
}
