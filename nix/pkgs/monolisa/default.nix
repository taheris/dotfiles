{ pkgs, lib, ... }:

let
  version = "2.012";
in
pkgs.stdenv.mkDerivation {
  pname = "monolisa-nerdfont-patch";
  inherit version;
  src = "./MonoLisa-Plus-${version}.zip";

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [
    pkgs.fontforge
    pkgs.python3
  ];

  buildPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    install -m755 -D ${./patch.py} \
      $out/bin/monolisa-nerdfont-patch
    install -m755 -D ${./font-patcher} $out/bin/font-patcher
    cp -r ${./bin} $out/bin/bin
    cp -r ${./src} $out/bin/src
  '';

  postFixup = ''
    wrapProgram $out/bin/monolisa-nerdfont-patch \
      --set PATH ${lib.makeBinPath (with pkgs; [ fontforge ])}
  '';
}
