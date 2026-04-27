{ my, den, ... }:

{
  den.aspects.shaun = {
    includes = [
      (den.provides.user-shell "zsh")
      den.provides.primary-user

      # shell
      my.zsh
      my.tmux
      my.alacritty
      my.starship
      my.vim

      # dev
      my.git
      my.python
      my.rust
      my.sql
      my.emacs
      my.agent

      # desktop
      my.niri
      my.dms
      my.stylix
      my.font
      my.librewolf
      my.flatpak
      my.input

      # secrets
      my.secrets
      my.gpg

      # misc
      my.dotfile
      my.home-base
    ];
  };
}
