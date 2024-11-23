{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin;

in
{
  home.file = {
    karabiner = mkIf isDarwin {
      source = ./karabiner.json;
      target = "${config.xdg.configHome}/karabiner/karabiner.json";
    };
  };

  programs.readline.variables = {
    editing-mode = "emacs";
  };

  gtk = {
    gtk2.extraConfig = ''
      gtk-key-theme-name = "Emacs"
    '';
    gtk3.extraConfig = {
      gtk-key-theme-name = "Emacs";
    };
  };

  dconf.settings."org/gnome/desktop/interface" = {
    gtk-key-theme = "Emacs";
  };
}
