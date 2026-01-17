{ lib, pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "bookerly";
  version = "2020.03";

  meta = {
    description = "Amazon's Bookerly font family";
    homepage = "https://www.amazon.com";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };

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
}
