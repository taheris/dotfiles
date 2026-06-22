{ ... }:

{
  flake.overlays.fixes =
    final: prev:
    {
      typstPackages = prev.typstPackages // {
        moderner-cv = prev.typstPackages.moderner-cv.overrideAttrs (_: {
          version = "0.2.1";
          src = final.fetchurl {
            url = "https://github.com/pavelzw/moderner-cv/archive/refs/tags/v0.2.1.tar.gz";
            hash = "sha256-w2IqUYwTfseL3g2A/8qjreMWP9nvJdppfx0QfnyvcQY=";
          };
        });
      };
    };
}
