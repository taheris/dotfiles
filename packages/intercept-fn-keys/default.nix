{ pkgs, ... }:

let
  version = "1.0.0";
in
pkgs.stdenv.mkDerivation {
  name = "intercept-fn-keys";
  inherit version;

  src = ./intercept.c;

  unpackPhase = ''
    cp $src intercept.c
  '';

  buildPhase = ''
    gcc -o intercept intercept.c
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp intercept $out/bin/
  '';
}
