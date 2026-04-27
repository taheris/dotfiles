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
  inherit (den.lib) aspects parametric;

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

    hasLinuxBuilder = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host has access to a remote Nix Linux builder.";
    };
  };

  optionsModule = { options.my = options; };

  bridge = host: { my = { inherit (host) user fontSize hasLinuxBuilder; }; };

  # Resolves the host's full homeManager aspect tree and forwards it onto the
  # standalone home. Mirrors `den.provides.host-aspects` (which fires from the
  # user ctx for bundled HM) but keyed off `home` so it works in the home ctx
  # where only `home` is bound.
  forwardHostAspects =
    { home, ... }:
    lib.optionalAttrs (home.host != null && home.user != null) {
      homeManager = aspects.resolve "homeManager" (
        parametric.fixedTo {
          host = home.host;
          user = home.user;
          inherit home;
        } home.host.aspect
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

  den.ctx.home.includes = [
    forwardHostAspects
    (
      { home, ... }:
      lib.optionalAttrs (home.host != null) {
        homeManager = bridge home.host;
      }
    )
  ];
}
