{ ... }:

{
  flake.overlays.fixes = final: prev: {
    # niri-flake still requires the 0.2 ABI, which was removed from unstable.
    libdisplay-info_0_2 = final.stable.libdisplay-info_0_2;

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
