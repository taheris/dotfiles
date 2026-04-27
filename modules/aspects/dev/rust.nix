{ ... }:

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

        sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];
      };
    };
}
