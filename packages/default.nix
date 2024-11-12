{ pkgs, ... }:

let
  inherit (pkgs) callPackage;

in
{
  monaco = callPackage ./monaco { };
  monacob = callPackage ./monacob { };
  #monolisa = callPackage ./monolisa {};
  sqlite-vss = callPackage ./sqlite-vss { };
}
