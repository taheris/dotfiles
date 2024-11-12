{ lib, pkgs, ... }:

let
  commit = "b77db4b6fc2e9df074f8db59cead862d7068e3d7";

  patcherVersion = "3.2.1";
  patcher = pkgs.fetchzip {
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${patcherVersion}/FontPatcher.zip";
    sha256 = "sha256-3s0vcRiNA/pQrViYMwU2nnkLUNUcqXja/jTWO49x3BU=";
    stripRoot = false;
  };
in
pkgs.stdenv.mkDerivation {
  pname = "otf-nerd-fonts-monacob-mono";
  version = "0.1.0";

  meta = {
    description = "MonacoB fonts patched with nerd-fonts";
    homepage = "https://github.com/vjpr/monaco-bold";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };

  src = pkgs.fetchFromGitHub {
    owner = "vjpr";
    repo = "monaco-bold";
    rev = commit;
    sha256 = "sha256-qiJK/h1Z5iLzmG4L693BjE9cPMIKv4cpP1c3w9fbDrs=";
  };

  buildInputs = [
    pkgs.fontforge
    pkgs.python3
  ];

  # Fix and patch fonts
  buildPhase = ''
    export PYTHONIOENCODING=utf8

    mkdir monacob-patched
    find monaco-bold-* -type f -name '*.otf' | xargs ${pkgs.python3}/bin/python3 \
      ${./monacob-font-patcher.py} --output-dir monacob-patched

    mkdir nerd-patched
    find monacob-patched -type f -name '*.otf' -exec ${pkgs.fontforge}/bin/fontforge -script \
      ${patcher}/font-patcher {} --mono --careful --complete --progressbars --outputdir nerd-patched \;
  '';

  installPhase = ''
    install -D -m644 nerd-patched/*.otf -t $out/share/fonts/opentype
  '';
}
