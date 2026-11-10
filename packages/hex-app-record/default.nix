{
  lib,
  makeWrapper,
  stdenv,
  swift,
  terminal-notifier,
}:

stdenv.mkDerivation {
  pname = "hex-app-record";
  version = "0.2.0";
  src = ./.;
  nativeBuildInputs = [
    swift
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    swiftc -swift-version 5 -parse-as-library -O Core.swift Record.swift -o hex-app-record \
      -target ${if stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64"}-apple-macosx13.0 \
      -framework AppKit -framework AudioToolbox -framework CoreMedia -framework ScreenCaptureKit
    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    swiftc -swift-version 5 -parse-as-library Core.swift Tests.swift -o tests \
      -target ${if stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64"}-apple-macosx13.0
    ./tests
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 hex-app-record "$out/bin/hex-app-record"
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram "$out/bin/hex-app-record" \
      --prefix PATH : ${lib.makeBinPath [ terminal-notifier ]}
  '';

  meta = {
    description = "Transcribe frontmost macOS application audio through Hex streams";
    mainProgram = "hex-app-record";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}
