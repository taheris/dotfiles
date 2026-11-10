{
  lib,
  rustPlatform,
  nodejs,
  stdenv,
  makeWrapper,
  terminal-notifier,
}:

rustPlatform.buildRustPackage {
  pname = "obs-video-crop";
  version = "0.1.0";
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
  nativeCheckInputs = [ nodejs ];
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ makeWrapper ];

  preConfigure = ''
    export HOME="$TMPDIR/home"
    export CARGO_HOME="$TMPDIR/cargo-home"
    mkdir -p "$HOME" "$CARGO_HOME"
  '';

  postCheck = ''
    node --test tests/*.test.cjs
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    wrapProgram "$out/bin/obs-video-crop" \
      --prefix PATH : ${lib.makeBinPath [ terminal-notifier ]}
  '';

  meta = {
    description = "Select a browser video and toggle OBS recording";
    mainProgram = "obs-video-crop";
    platforms = lib.platforms.unix;
  };
}
