{ my, den, ... }:

# User aspects only activate the homeManager class — nixos/darwin blocks
# in any included aspect silently no-op here.
{
  den.aspects.shaun = {
    includes = [
      (den.provides.user-shell "zsh")
      den.provides.primary-user

      # system
      my.base

      # cli
      my.alacritty
      my.dotfile
      my.starship
      my.tmux
      my.vim
      my.zsh

      # dev
      my.agent
      my.emacs
      my.git
      my.python
      my.rust
      my.sql

      # services
      my.ssh

      # secrets
      my.secrets
    ];

    homeManager = {
      programs.git = {
        settings.user = {
          name = "Shaun Taheri";
          email = "gpg@taheris.net";
        };
        signing = {
          format = "openpgp";
          key = "1C2BE6B85F923891";
          signByDefault = true;
        };
      };
    };
  };
}
