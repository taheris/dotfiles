{ ... }:

{
  flake.overlays.fixes = final: prev: {
    # niri-flake still requires the 0.2 ABI, which was removed from unstable.
    libdisplay-info_0_2 = final.stable.libdisplay-info_0_2;

    # Avoid building the .NET/Swift toolchain for pre-commit's Darwin tests.
    # Remove once resolved upstream: https://github.com/NixOS/nixpkgs/issues/584390.
    pre-commit =
      if prev.stdenv.hostPlatform.isDarwin then
        prev.pre-commit.override {
          dotnetCorePackages = {
            sdk_8_0-source.meta.platforms = [ ];
          };
        }
      else
        prev.pre-commit;

    # Use the standalone release to avoid Marksman's .NET build toolchain on Darwin.
    # Remove when nixpkgs provides a cached or standalone Darwin Marksman:
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ma/marksman/package.nix
    marksman =
      if prev.stdenv.hostPlatform.isDarwin then
        final.stdenvNoCC.mkDerivation {
          inherit (prev.marksman) pname version;
          src = final.fetchurl {
            url = "https://github.com/artempyanykh/marksman/releases/download/${prev.marksman.version}/marksman-macos";
            hash = "sha256-aoAcF7WsDbppeHxSgrOzvUFuZsliU/rgmNMRxrvRgzs=";
          };
          dontUnpack = true;
          installPhase = ''
            runHook preInstall
            install -Dm755 "$src" "$out/bin/marksman"
            runHook postInstall
          '';
          nativeInstallCheckInputs = [ final.versionCheckHook ];
          doInstallCheck = true;
          meta = prev.marksman.meta // {
            platforms = final.lib.platforms.darwin;
          };
        }
      else
        prev.marksman;

    # sphinxHook skips documentation phases with Khal's structured attributes.
    # Remove once nixpkgs-unstable includes https://github.com/NixOS/nixpkgs/pull/573479.
    khal = prev.khal.overrideAttrs {
      __structuredAttrs = false;
    };

    # Accept Cython's new TypeError wording without disabling the regression test.
    # Remove once nixpkgs-unstable includes https://github.com/NixOS/nixpkgs/pull/576063.
    pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
      (pythonFinal: pythonPrev: {
        pyopenjtalk-plus = pythonPrev.pyopenjtalk-plus.overridePythonAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace tests/test_frontend.py \
              --replace-fail 'match="must be str"' 'match="must be str|Expected str, got int"'
          '';
        });
      })
    ];

    # Backport the Python bindings build fix; also applies to speechd-minimal.
    # Remove once nixpkgs-unstable includes https://github.com/NixOS/nixpkgs/pull/576062.
    speechd = prev.speechd.overrideAttrs (old: {
      nativeBuildInputs =
        old.nativeBuildInputs ++ builtins.filter (input: (input.pname or "") == "python3") old.buildInputs;
      buildInputs = builtins.filter (input: (input.pname or "") != "python3") old.buildInputs;
    });

    # Use C++17 for demangling tests; GCC 16 warnings fail the test harness.
    # Remove when nixpkgs-unstable passes these tests without the override:
    # https://github.com/NixOS/nixpkgs/commits/nixpkgs-unstable/pkgs/by-name/lt/ltrace
    ltrace = prev.ltrace.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace testsuite/ltrace.minor/demangle.exp \
          --replace-fail '[list debug ' '[list debug additional_flags=-std=c++17 '
      '';
    });
  };
}
