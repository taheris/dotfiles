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

  modifications = final: prev: {
    # TODO: remove once NixOS/nixpkgs#509064 lands in nixos-unstable
    # Fixes ibis-framework tests against duckdb 1.5.1
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (pyFinal: pyPrev: {
        ibis-framework = pyPrev.ibis-framework.overrideAttrs (old: {
          pytestFlags = (old.pytestFlags or [ ]) ++ [
            "-Wignore:fetch_arrow_table:DeprecationWarning"
            "-Wignore:fetch_record_batch:DeprecationWarning"
          ];
          disabledTests = (old.disabledTests or [ ]) ++ [
            "test_decimal_literal[duckdb-decimal-big]"
            "test_empty_array_string_join[duckdb]"
          ];
        });
      })
    ];

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
