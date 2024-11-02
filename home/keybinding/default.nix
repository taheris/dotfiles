{ ... }:

{
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
