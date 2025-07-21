{ pkgs, ... }:

let
  inherit (pkgs) callPackage;

in
{
  intercept-fn-keys = callPackage ./intercept-fn-keys { };
  monaco = callPackage ./monaco { };
  monacob = callPackage ./monacob { };
  #monolisa = callPackage ./monolisa {};
  sqlite-vss = callPackage ./sqlite-vss { };
}
