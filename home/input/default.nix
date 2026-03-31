{
  config,
  lib,
  outputs,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin isLinux;
  mouser = outputs.packages.${pkgs.stdenv.hostPlatform.system}.mouser;

in
{
  imports = [
    ./voice.nix
  ];

  home.file = {
    karabiner = mkIf isDarwin {
      source = ./karabiner.json;
      target = "${config.xdg.configHome}/karabiner/karabiner.json";
    };

    mouserConfig = mkIf isLinux {
      source = ./mouser.json;
      target = "${config.xdg.configHome}/Mouser/config.json";
    };
  };

  home.packages = mkIf isLinux [
    mouser
    pkgs.bazecor
    pkgs.yubikey-touch-detector
  ];

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
      ExecStart = "${mouser}/bin/mouser --start-hidden";
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
      After = [ "mouser.service" ];
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
}
