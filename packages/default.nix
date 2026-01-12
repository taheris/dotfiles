{ pkgs, ... }:

let
  inherit (pkgs) callPackage;

in
{
  intercept-fn-keys = callPackage ./intercept-fn-keys { };
  monaco = callPackage ./monaco { };
  monacob = callPackage ./monacob { };
  sqlite-vss = callPackage ./sqlite-vss { };
  tws = callPackage ./tws { };
}
