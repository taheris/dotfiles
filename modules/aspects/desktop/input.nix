{ ... }:
{
  my.input.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf;
      inherit (pkgs.stdenv) isDarwin isLinux;

      sox = pkgs.sox.override { enableLame = true; };
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
      home.file = {
        karabiner = mkIf isDarwin {
          source = ./_input/karabiner.json;
          target = "${config.xdg.configHome}/karabiner/karabiner.json";
        };

        mouserConfig = mkIf isLinux {
          source = ./_input/mouser.json;
          target = "${config.xdg.configHome}/Mouser/config.json";
        };
      };

      home.packages = [
        sox
      ]
      ++ (
        if isLinux then
          [
            pkgs.mouser
            pkgs.bazecor
            pkgs.yubikey-touch-detector
          ]
        else
          [ ]
      );

      home.activation.soxApp = mkIf isDarwin (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.rsync}/bin/rsync -a --delete "${soxApp}/Applications/Sox.app" "/Applications/"
        ''
      );

      dconf.settings = mkIf isLinux {
        "org/gnome/desktop/interface" = {
          gtk-key-theme = "Emacs";
        };
      };

      gtk = mkIf isLinux {
        gtk2.extraConfig = ''
          gtk-key-theme-name = "Emacs"
        '';

        gtk3.extraConfig = {
          gtk-key-theme-name = "Emacs";
        };
      };

      programs.readline.variables = {
        editing-mode = "emacs";
      };

      systemd.user.services.mouser = mkIf isLinux {
        Unit = {
          Description = "Mouser - Logitech mouse remapper";
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.mouser}/bin/mouser --start-hidden";
          Environment = [ "PYTHONUNBUFFERED=1" ];
          Restart = "always";
          RestartSec = 3;
          KillSignal = "SIGKILL";
          TimeoutStopSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      systemd.user.services.mouser-resume = mkIf isLinux {
        Unit = {
          Description = "Restart Mouser on system resume";
        };
        Service = {
          Type = "exec";
          ExecStart = pkgs.writeShellScript "mouser-resume-watch" ''
            ${pkgs.dbus}/bin/dbus-monitor --system \
              "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" |
              while read -r line; do
                case "$line" in
                  *"boolean false"*)
                    sleep 2
                    ${pkgs.systemd}/bin/systemctl --user restart mouser.service
                    ;;
                esac
              done
          '';
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      systemd.user.services.yubikey-touch-detector = mkIf isLinux {
        Unit = {
          Description = "YubiKey touch detector";
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector";
          Environment = [ "YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=true" ];
          Restart = "always";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
