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

  Bookerly-Regular = mkFont "Bookerly-Regular" {
    url = "https://jb55.com/s/Bookerly-Regular.ttf";
    sha256 = "1db94d4ab763f812b3fe505c02cdeb0927251c118cc65322be23eb93a70eafd7";
  };

  Bookerly-RegularItalic = mkFont "Bookerly-RegularItalic" {
    url = "https://jb55.com/s/Bookerly-RegularItalic.ttf";
    sha256 = "6e364837e08fa89c0fed287a13c7149567ab5657847f666e45e523ecc9c7820b";
  };

  Bookerly-Bold = mkFont "Bookerly-Bold" {
    url = "https://jb55.com/s/Bookerly-Bold.ttf";
    sha256 = "367a28ceb9b2c79dbe5956624f023a54219d89f31d6d2e81e467e202273d40da";
  };

  Bookerly-BoldItalic = mkFont "Bookerly-BoldItalic" {
    url = "https://jb55.com/s/Bookerly-BoldItalic.ttf";
    sha256 = "d975e3260e26f1b33fc50b00540caece84a0800e9bc900922cf200645e79693f";
  };

  bookerly = [
    Bookerly-Regular
    Bookerly-RegularItalic
    Bookerly-Bold
    Bookerly-BoldItalic
  ];

in
{
  home.packages =
    with pkgs;
    [
      julia-mono
      libre-baskerville
      monaco
      monacob
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-extra
    ]
    ++ bookerly;

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
