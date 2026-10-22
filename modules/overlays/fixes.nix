{ ... }:

{
  flake.overlays.fixes = final: prev: {
    # niri-flake still requires the 0.2 ABI, which was removed from unstable.
    libdisplay-info_0_2 = final.stable.libdisplay-info_0_2;

    # sphinxHook skips documentation phases with Khal's structured attributes.
    # Remove when the nixpkgs Sphinx hook supports structured attributes:
    # https://github.com/NixOS/nixpkgs/commits/nixpkgs-unstable/pkgs/development/interpreters/python/hooks/sphinx-hook.sh
    khal = prev.khal.overrideAttrs {
      __structuredAttrs = false;
    };

    # Accept Cython's new TypeError wording without disabling the regression test.
    # Remove when upstream accepts both messages:
    # https://github.com/tsukumijima/pyopenjtalk-plus/commits/master/tests/test_frontend.py
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
