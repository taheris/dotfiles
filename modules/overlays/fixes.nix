{ ... }:

{
  flake.overlays.fixes = final: prev: {
    # Remove once the CUDA fix reaches nixpkgs-unstable:
    # https://nixpk.gs/pr-tracker.html?pr=568318
    cudaPackages = prev.cudaPackages.overrideScope (
      cudaFinal: _: {
        buildRedist = cudaFinal.callPackage (final.applyPatches {
          name = "cuda-buildRedist";
          src = "${prev.path}/pkgs/development/cuda-modules/buildRedist";
          patches = [
            (final.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/commit/65fe9eae2b57c9cb7bfbe5f352944d01b5c5be0b.patch";
              relative = "pkgs/development/cuda-modules/buildRedist";
              hash = "sha256-A3dxg8B+BKMZ2NxexQK9/bTVtmuGxxkFiH53OfI7IXg=";
            })
          ];
        }) { };
      }
    );

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

    # Remove once the mosh GCC 16 fix reaches nixpkgs-unstable:
    # https://nixpk.gs/pr-tracker.html?pr=568002
    mosh = final.callPackage "${
      final.applyPatches {
        name = "mosh-package";
        src = "${prev.path}/pkgs/by-name/mo/mosh";
        patches = [
          (final.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/3f6a1a107f818579c63976147c37050c2b722997.patch";
            relative = "pkgs/by-name/mo/mosh";
            hash = "sha256-GzEfUtwz6j329vReYcDMjMFQ0UGEMS0VIFZ807a2KKY=";
          })
        ];
      }
    }/package.nix" { };
  };
}
