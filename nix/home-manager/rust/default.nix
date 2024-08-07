{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      cargo-audit
      cargo-bloat
      cargo-expand
      cargo-flamegraph
      cargo-fuzz
      cargo-outdated
      cargo-sweep
      cargo-release
      cargo-rr
      cargo-udeps
      cargo-update
      cargo-watch
      rr
      rustup
      sccache
      wasm-pack
    ];

    sessionPath = [ "$HOME/.cargo/bin" ];
    sessionVariables = {
      RUSTC_WRAPPER = "sccache";
    };
  };
}
