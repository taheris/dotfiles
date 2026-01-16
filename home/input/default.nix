{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin isLinux;

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

    solaarConfig = mkIf isLinux {
      source = ./solaar-config.yaml;
      target = "${config.xdg.configHome}/solaar/config.yaml";
    };

    solaarRules = mkIf isLinux {
      source = ./solaar-rules.yaml;
      target = "${config.xdg.configHome}/solaar/rules.yaml";
    };
  };

  home.packages = mkIf isLinux [
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
