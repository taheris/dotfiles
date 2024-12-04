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
  home.file = {
    karabiner = mkIf isDarwin {
      source = ./karabiner.json;
      target = "${config.xdg.configHome}/karabiner/karabiner.json";
    };
  };

  home.packages = mkIf isLinux [
    pkgs.bazecor
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
}
