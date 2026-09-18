{ ... }:

{
  flake.overlays.fixes = final: prev: {
    # niri-flake still requires the 0.2 ABI, which was removed from unstable.
    libdisplay-info_0_2 = final.stable.libdisplay-info_0_2;

    # Remove once nixpkgs-unstable includes the corrected tree-sitter-cuda hash: https://github.com/NixOS/nixpkgs/pull/564140
    tree-sitter-grammars = prev.tree-sitter-grammars.overrideScope (
      _: grammarPrev: {
        tree-sitter-cuda = grammarPrev.tree-sitter-cuda.overrideAttrs (_: {
          src = final.fetchFromGitHub {
            owner = "tree-sitter-grammars";
            repo = "tree-sitter-cuda";
            rev = "d58080a327756e4d1d16ec329ba7cb2048f6c6cd";
            hash = "sha256-s2qrZx5fEu/I6xE2paX/Nlmgvo6T27qqvy1cI8iznAA=";
          };
        });
      }
    );

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
