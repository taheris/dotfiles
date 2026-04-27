{ my, den, ... }:
{
  den.aspects.shaun = {
    includes = [
      (den.provides.user-shell "zsh")
      den.provides.primary-user

      # Shells & terminals
      my.zsh
      my.tmux
      my.alacritty
      my.starship
      my.vim

      # Dev
      my.git
      my.python
      my.rust
      my.sql
      my.emacs
      my.agent

      # Desktop (Linux-gated where appropriate inside aspects)
      my.niri
      my.dms
      my.stylix
      my.font
      my.librewolf
      my.flatpak
      my.input

      # Secrets
      my.secrets
      my.gpg

      # Misc
      my.dotfile
      my.home-base
    ];
  };
}
