{ inputs, ... }:

{
  additions =
    final: _prev:
    import ../packages {
      inherit inputs;
      pkgs = final;
    }
    // {
      beads = inputs.wrapix.packages.${final.stdenv.hostPlatform.system}.beads;
      wrapix-builder = inputs.wrapix.packages.${final.stdenv.hostPlatform.system}.wrapix-builder;
      wrapix-notifyd = inputs.wrapix.packages.${final.stdenv.hostPlatform.system}.wrapix-notifyd;
    };

  modifications =
    final: prev:
    let
      # Remove when https://github.com/pytest-dev/pytest/issues/13112 is fixed.
      pyOverride =
        python:
        python.override (old: {
          packageOverrides = final.lib.composeExtensions (old.packageOverrides or (_: _: { })) (
            _: pyprev: {
              cli-helpers = pyprev.cli-helpers.overridePythonAttrs (_: { doCheck = false; });
            }
          );
        });
    in
    {
      python3 = pyOverride prev.python3;
      python313 = pyOverride prev.python313;

      typstPackages = prev.typstPackages // {
        moderner-cv = prev.typstPackages.moderner-cv.overrideAttrs (old: {
          version = "0.2.1";
          src = final.fetchurl {
            url = "https://github.com/pavelzw/moderner-cv/archive/refs/tags/v0.2.1.tar.gz";
            hash = "sha256-w2IqUYwTfseL3g2A/8qjreMWP9nvJdppfx0QfnyvcQY=";
          };
        });
      };
    };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
