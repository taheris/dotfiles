{
  lib,
  pkgs,
  host,
  ...
}:

let
  inherit (lib) mkIf;

  packages = with pkgs; [
    cargo-audit
    cargo-bloat
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
    rr
  ];

in
{
  home = {
    packages = packages ++ (if host ? isLinux then linuxPackages else [ ]);

    sessionPath = [ "$HOME/.cargo/bin" ];
    sessionVariables = {
      RUSTC_WRAPPER = "sccache";
    };
  };
}
