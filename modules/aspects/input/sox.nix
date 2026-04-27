{ ... }:

{
  my.sox.homeManager =
    { lib, pkgs, ... }:
    let
      inherit (lib) mkIf;
      inherit (pkgs.stdenv) isDarwin;

      sox = pkgs.sox.override { enableLame = true; };

      # On macOS, sox requires a .app bundle to obtain microphone permissions.
      soxApp = pkgs.stdenv.mkDerivation {
        name = "Sox";
        version = "1.0";

        src = pkgs.writeTextDir "dummy" "";

        buildInputs = [ sox ];

        installPhase = ''
          mkdir -p $out/Applications/Sox.app/Contents/MacOS

          cat > $out/Applications/Sox.app/Contents/MacOS/Sox << 'EOF'
          #!/bin/bash
          export PATH="${sox}/bin:$PATH"
          sox -t coreaudio default "$1"
          EOF

          chmod +x $out/Applications/Sox.app/Contents/MacOS/Sox

          cat > $out/Applications/Sox.app/Contents/Info.plist << 'EOF'
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>CFBundleExecutable</key>
              <string>Sox</string>
              <key>CFBundleIdentifier</key>
              <string>org.nixos.audiorecorder</string>
              <key>CFBundleName</key>
              <string>Sox</string>
              <key>CFBundleVersion</key>
              <string>1.0</string>
              <key>NSMicrophoneUsageDescription</key>
              <string>This app needs microphone access to record audio.</string>
          </dict>
          </plist>
          EOF
        '';
      };
    in
    {
      home.packages = [ sox ];

      home.activation.soxApp = mkIf isDarwin (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.rsync}/bin/rsync -a --delete "${soxApp}/Applications/Sox.app" "/Applications/"
        ''
      );
    };
}
