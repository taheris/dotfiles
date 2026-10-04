{
  lib,
  fetchurl,
  stdenvNoCC,
  undmg,
}:

# Keep the licensed major version; remove this pin only with a newer Cookie license.
# Vendor archive: https://sweetpproductions.com/products/cookie7/Cookie.dmg
stdenvNoCC.mkDerivation {
  pname = "cookie7";
  version = "7.9.7";

  src = fetchurl {
    url = "https://sweetpproductions.com/products/cookie7/Cookie.dmg";
    hash = "sha256-a3U9YLSowCqdtJjrXQ4zfvR2gPkrlVY8RLQ1MVNIuno=";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = "Cookie.app";

  # Preserve the vendor's code signature.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications/Cookie.app"
    cp -R . "$out/Applications/Cookie.app"
    runHook postInstall
  '';

  meta = {
    description = "Cookie and tracking data manager (licensed version 7)";
    homepage = "https://sweetpproductions.com/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
