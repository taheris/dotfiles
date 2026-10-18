{ inputs, lib, ... }:

let
  inherit (lib) hasSuffix optionalAttrs;
in
{
  flake.overlays.packages =
    final: prev:
    let
      inherit (prev.stdenv.hostPlatform) isDarwin isLinux;

      callPackage = final.callPackage;
      system = prev.stdenv.hostPlatform.system;

    in
    {
      bookerly = callPackage ../../packages/bookerly { };
      monaco = callPackage ../../packages/monaco { };
      monacob = callPackage ../../packages/monacob { };
      sqlite-vss = callPackage ../../packages/sqlite-vss { };
      terminal-bridge = callPackage ../../packages/terminal-bridge { };

      beads = inputs.wrix.packages.${system}.beads;
      loom = inputs.loom.packages.${system}.loom;
      wrix = inputs.wrix.packages.${system}.wrix;
      wrix-notify-host = inputs.wrix.packages.${system}.wrix-notify-host;
      wrix-builder = inputs.wrix.packages.${system}.wrix-builder;
      wrix-notifyd = inputs.wrix.packages.${system}.wrix-notifyd;
      wrix-focus-notification = inputs.wrix.packages.${system}.wrix-focus-notification;

      stable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    }
    // optionalAttrs isDarwin {
      cookie7 = callPackage ../../packages/cookie7 { };
    }
    // optionalAttrs isLinux {
      apple-display-backlight = callPackage ../../packages/apple-display-backlight {
        kernel = final.linuxPackages_latest.kernel;
      };
      r8152 = callPackage ../../packages/r8152 {
        kernel = final.linuxPackages_latest.kernel;
      };
      intercept-fn-keys = callPackage ../../packages/intercept-fn-keys { };
      librepods = callPackage ../../packages/librepods { };
      mouser = callPackage ../../packages/mouser { };
      tws = callPackage ../../packages/tws { };
    }
    // optionalAttrs (system == "x86_64-linux") {
      strata = callPackage ../../packages/strata { };
      tailscale-nextdns = callPackage ../../packages/tailscale-nextdns {
        tailscale = prev.tailscale;
      };
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
          terminal-bridge
          ;
      }
      // optionalAttrs (hasSuffix "darwin" system) {
        inherit (pkgs) cookie7;
      }
      // optionalAttrs (hasSuffix "linux" system) {
        inherit (pkgs)
          apple-display-backlight
          intercept-fn-keys
          librepods
          r8152
          mouser
          tws
          ;
      }
      // optionalAttrs (system == "x86_64-linux") {
        inherit (pkgs) strata tailscale-nextdns;
      };

      checks = {
        terminal-bridge = pkgs.terminal-bridge;
      }
      // optionalAttrs (system == "x86_64-linux") {
        strata-smoke = pkgs.strata.tests.smoke;
        tailscale-nextdns = pkgs.tailscale-nextdns;
      };
    };

}
