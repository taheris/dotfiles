{ ... }:

{
  my.bettertouchtool.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;

    in
    {
      xdg.configFile = mkIf isDarwin (
        import ./_bettertouchtool/presets.nix {
          inherit lib;
          configHome = config.xdg.configHome;
          presetsDir = ./_bettertouchtool;
        }
      );
    };
}
