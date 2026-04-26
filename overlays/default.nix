{ inputs, ... }:

{
  additions =
    final: _prev:
    import ../packages {
      inherit inputs;
      pkgs = final;
      inherit (inputs.nixpkgs) lib;
      inherit (_prev.stdenv) isLinux;
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
              # OOM (Killed: 9, exit code 137) during check phases on aarch64-darwin.
              # Same class of issue as https://github.com/NixOS/nixpkgs/issues/330839
              av = pyprev.av.overridePythonAttrs (_: {
                doCheck = false;
                pythonImportsCheck = [ ];
              });
              imageio = pyprev.imageio.overridePythonAttrs (_: {
                doCheck = false;
              });
              cli-helpers = pyprev.cli-helpers.overridePythonAttrs (_: {
                doCheck = false;
              });
            }
          );
        });
    in
    {
      # Strip libgbm/playwright from d2 on Darwin — libdrm is Linux-only.
      # https://github.com/NixOS/nixpkgs/pull/488723
      d2 =
        if prev.stdenv.isDarwin then
          prev.d2.overrideAttrs (old: {
            buildInputs = builtins.filter (
              dep:
              !(builtins.elem (dep.pname or "") [
                "mesa-libgbm"
                "playwright-browsers"
              ])
            ) (old.buildInputs or [ ]);
            nativeBuildInputs = builtins.filter (dep: !(builtins.elem (dep.pname or "") [ "makeWrapper" ])) (
              old.nativeBuildInputs or [ ]
            );
            postInstall = ''
              installManPage ci/release/template/man/d2.1
            '';
          })
        else
          prev.d2;

      # checkPhase hangs on aarch64-darwin (code signing issue with fish/zsh).
      # https://github.com/NixOS/nixpkgs/issues/513019
      direnv =
        if prev.stdenv.isDarwin then
          prev.direnv.overrideAttrs (_: {
            doCheck = false;
          })
        else
          prev.direnv;

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
