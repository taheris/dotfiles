{ lib, ... }:
{
  den.default = {
    nixos.system.stateVersion = "24.11";
    darwin.system.stateVersion = 6;
    homeManager.home.stateVersion = "26.05";
  };

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
  den.schema.host.options.fontSize = lib.mkOption {
    type = lib.types.int;
    default = 13;
    description = "Default font size for terminal/UI on this host.";
  };
}
