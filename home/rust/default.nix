{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkMerge;
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

        target.x86_64-unknown-linux-gnu =
          if isLinux then
            {
              linker = "clang";
              rustflags = [
                "-C"
                "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"
              ];
            }
          else
            { };
      };
    };

    sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];
  };
}
