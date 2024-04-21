{ pkgs, ... }:

{
  imports = [
    ./alacritty
    ./dotfile
    ./emacs
    ./font
    ./gpg
    ./git
    ./keybinding
    ./nix
    ./rust
    ./starship
    ./tmux
    ./vim
    ./zsh
  ];

  home = {
    username = "shaun";
    homeDirectory = "/home/shaun";

    packages = with pkgs; [
      btop
      docker-compose
      dnsutils
      ethtool
      fd
      gnumake
      gnupg
      iftop
      iotop
      jq
      lsof
      ltrace
      mtr
      pciutils
      postgresql
      ripgrep
      tree
      unzip
      usbutils
      zip
    ];
  };

  programs = {
    home-manager.enable = true;
    librewolf.enable = true;
  };

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
