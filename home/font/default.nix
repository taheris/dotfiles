{ pkgs, ... }:

let
  inherit (pkgs.stdenv) mkDerivation;

  mkFont =
    font: url:
    mkDerivation rec {
      name = "${font}-${version}";
      src = pkgs.fetchurl url;
      version = "1.0";
      phases = [ "installPhase" ];

      installPhase = ''
        mkdir -p $out/share/fonts/${font}
        cp -v ${src} $out/share/fonts/${font}
      '';
    };

  bookerly = pkgs.stdenvNoCC.mkDerivation {
    pname = "bookerly";
    version = "2020.03";

    src = pkgs.fetchzip {
      url = "https://m.media-amazon.com/images/G/01/mobile-apps/dex/alexa/branding/Amazon_Typefaces_Complete_Font_Set_Mar2020.zip";
      hash = "sha256-CK7WSXkJkcwMxwdeW31Zs7p2VdZeC3xbpOnmd6Rr9go=";
    };

    installPhase = ''
      runHook preInstall

      install -Dm644 Bookerly/*.ttf -t $out/share/fonts/opentype
      install -Dm644 'Bookerly Display'/*.ttf -t $out/share/fonts/opentype

      runHook postInstall
    '';
  };

in
{
  home.packages =
    with pkgs;
    [
      bookerly
      julia-mono
      libre-baskerville
      monaco
      monacob
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-extra
    ] ;

  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      monospace = [ "MonacoB Nerd Font Mono" ];
      serif = [ "Bookerly" ];
      sansSerif = [ "Noto Sans" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
