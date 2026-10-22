{ ... }:

{
  flake.overlays.fixes = final: prev: {
    # niri-flake still requires the 0.2 ABI, which was removed from unstable.
    libdisplay-info_0_2 = final.stable.libdisplay-info_0_2;

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
