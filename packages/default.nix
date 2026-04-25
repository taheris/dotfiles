{
  pkgs,
  lib,
  isLinux,
  ...
}:

let
  inherit (lib) optionalAttrs;
  inherit (pkgs) callPackage;

in
{
  bookerly = callPackage ./bookerly { };
  monaco = callPackage ./monaco { };
  monacob = callPackage ./monacob { };
  sqlite-vss = callPackage ./sqlite-vss { };
}
// optionalAttrs isLinux {
  apple-display-backlight = callPackage ./apple-display-backlight {
    kernel = pkgs.linuxPackages_latest.kernel;
  };
  intercept-fn-keys = callPackage ./intercept-fn-keys { };
  mouser = callPackage ./mouser { };
  tws = callPackage ./tws { };
}
