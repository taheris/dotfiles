{ inputs, ... }:

{
  my.rust.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib) mkIf mkMerge optionalAttrs;
      inherit (pkgs.stdenv) isLinux;
      inherit (pkgs.stdenv.hostPlatform) system;

      # Reuse the sandbox's exact toolchain derivation — sccache hashes the
      # compiler binary, so a re-instantiated fenix would miss cross-boundary.
      wrixLib = inputs.wrix.legacyPackages.${system}.lib;
      wrixToolchain = wrixLib.profiles.rust.toolchain;

      packages = with pkgs; [
        cargo-audit
        cargo-bloat
        cargo-deny
        cargo-expand
        cargo-flamegraph
        cargo-fuzz
        cargo-outdated
        cargo-sweep
        cargo-release
        cargo-udeps
        cargo-update
        cargo-watch
        rustup
        sccache
        tokei
        wasm-pack
      ];

      linuxPackages = with pkgs; [
        cargo-rr
        cargo-valgrind
        clang
        mold
        rr
      ];

    in
    {
      home = {
        packages = mkMerge [
          packages
          (mkIf isLinux linuxPackages)
        ];

        file.cargo = {
          target = ".cargo/config.toml";
          source = (pkgs.formats.toml { }).generate "cargo-config" {
            build = {
              rustc-wrapper = "${pkgs.sccache}/bin/sccache";
            };

            profile.dev = {
              split-debuginfo = "unpacked";
            };

            target.x86_64-unknown-linux-gnu = optionalAttrs isLinux {
              linker = "clang";
              rustflags = [
                "-C"
                "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"
              ];
            };
          };
        };

        # Fenix ahead of rustup so the emacs daemon picks the same rustc
        # as the sandbox, not rustup's shim.
        sessionPath = [
          "${wrixToolchain}/bin"
          "${config.home.homeDirectory}/.cargo/bin"
        ];

        # CARGO_INCREMENTAL=0 is load-bearing — sccache refuses to cache any
        # rustc invocation built with -C incremental=...
        sessionVariables = mkIf isLinux {
          RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
          SCCACHE_DIR = "${config.home.homeDirectory}/.cache/sccache";
          SCCACHE_CACHE_SIZE = "50G";
          CARGO_INCREMENTAL = "0";
          RUST_SRC_PATH = "${wrixToolchain}/lib/rustlib/src/rust/library";
        };
      };
    };
}
