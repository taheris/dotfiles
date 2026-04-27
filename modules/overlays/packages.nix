{ inputs, lib, ... }:

let
  inherit (lib) hasSuffix optionalAttrs;
in
{
  flake.overlays.packages =
    final: prev:
    let
      callPackage = final.callPackage;
      system = final.stdenv.hostPlatform.system;
      isLinux = prev.stdenv.isLinux;

    in
    {
      bookerly = callPackage ../../packages/bookerly { };
      monaco = callPackage ../../packages/monaco { };
      monacob = callPackage ../../packages/monacob { };
      sqlite-vss = callPackage ../../packages/sqlite-vss { };

      beads = inputs.wrapix.packages.${system}.beads;
      wrapix-builder = inputs.wrapix.packages.${system}.wrapix-builder;
      wrapix-notifyd = inputs.wrapix.packages.${system}.wrapix-notifyd;

      stable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    }
    // optionalAttrs isLinux {
      apple-display-backlight = callPackage ../../packages/apple-display-backlight {
        kernel = final.linuxPackages_latest.kernel;
      };
      intercept-fn-keys = callPackage ../../packages/intercept-fn-keys { };
      mouser = callPackage ../../packages/mouser { };
      tws = callPackage ../../packages/tws { };
    };

  perSystem =
    { pkgs, system, ... }:
    {
      packages = {
        inherit (pkgs)
          bookerly
          monaco
          monacob
          sqlite-vss
          ;
      }
      // optionalAttrs (hasSuffix "linux" system) {
        inherit (pkgs)
          apple-display-backlight
          intercept-fn-keys
          mouser
          tws
          ;
      };
    };

}
