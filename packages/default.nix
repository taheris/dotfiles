{ pkgs, ... }:

let
  inherit (pkgs) callPackage;

in
{
  apple-display-backlight = callPackage ./apple-display-backlight {
    kernel = pkgs.linuxPackages_latest.kernel;
  };
  bookerly = callPackage ./bookerly { };
  intercept-fn-keys = callPackage ./intercept-fn-keys { };
  monaco = callPackage ./monaco { };
  monacob = callPackage ./monacob { };
  mouser = callPackage ./mouser { };
  sqlite-vss = callPackage ./sqlite-vss { };
  tws = callPackage ./tws { };
}
