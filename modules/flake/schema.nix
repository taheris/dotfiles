{ den, lib, ... }:

# Host-level schema options and the aspects that bridge them into the per-class
# config so they're readable via `config.my.*` from any nixos/darwin/homeManager
# module.
#
# The bridge fires from two contexts:
#   - host ctx: nixos/darwin systems and bundled hm users (via host-aspects)
#   - home ctx: standalone home-manager — also forwards the host's homeManager
#     aspect tree (gpg, stylix, niri, ...) so standalone @host stays in parity
#     with bundled HM.
let
  inherit (den.lib) aspects;

  options = {
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

    builders = lib.mkOption {
      type = lib.types.submodule {
        options = {
          wrix.enable = lib.mkEnableOption "the local wrix Linux builder";
          nix.enable = lib.mkEnableOption "the remote nix Linux builder";
        };
      };
      default = { };
      description = "Linux builders available to this host.";
    };
  };

  optionsModule = {
    options.my = options;
  };

  bridge = host: { my = { inherit (host) user fontSize builders; }; };

  # Resolves the host's full homeManager aspect tree (including the my.host
  # bridge) onto the standalone home. Mirrors `den.batteries.host-aspects`
  # (which fires from the user ctx for bundled HM) but keyed off `home` so it
  # works in the home ctx where only `home` is bound.
  forwardHostAspects =
    { home, ... }:
    lib.optionalAttrs (home.host != null && home.user != null) {
      homeManager = aspects.resolveImports "homeManager" (
        home.host.aspect
        // {
          __scopeHandlers = aspects.fx.handlers.constantHandler {
            host = home.host;
            user = home.user;
            inherit home;
          };
        }
      );
    };

in
{
  den.schema.host.options = options;

  den.default = {
    nixos.imports = [ optionsModule ];
    darwin.imports = [ optionsModule ];
    homeManager.imports = [ optionsModule ];
  };

  my.host =
    { host, ... }:
    {
      nixos = bridge host;
      darwin = bridge host;
      homeManager = bridge host;
    };

  den.schema.home.includes = [ forwardHostAspects ];
}
