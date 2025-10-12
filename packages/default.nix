{ pkgs, ... }:

let
  inherit (pkgs) callPackage;

in
{
  claude-code-acp = callPackage ./claude-code-acp { };
  intercept-fn-keys = callPackage ./intercept-fn-keys { };
  monaco = callPackage ./monaco { };
  monacob = callPackage ./monacob { };
  sqlite-vss = callPackage ./sqlite-vss { };
  tws = callPackage ./tws { };
}
