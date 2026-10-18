{
  lib,
  rustPlatform,
  stdenv,
  makeWrapper,
  tmux,
  procps,
  alacritty,
}:

rustPlatform.buildRustPackage {
  pname = "terminal-bridge";
  version = "0.1.0";
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ tmux ] ++ lib.optionals stdenv.hostPlatform.isLinux [ procps ];

  preConfigure = ''
    export HOME="$TMPDIR/home"
    export CARGO_HOME="$TMPDIR/cargo-home"
    mkdir -p "$HOME" "$CARGO_HOME"
  '';

  postInstall = ''
    wrapProgram "$out/bin/terminal-bridge" \
      --prefix PATH : ${
        lib.makeBinPath (
          [ tmux ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            procps
            alacritty
          ]
        )
      }
  '';

  meta = {
    description = "Terminal-aware niri and OmniWM slurp/expel using live tmux panes";
    mainProgram = "terminal-bridge";
    platforms = lib.platforms.unix;
  };
}
