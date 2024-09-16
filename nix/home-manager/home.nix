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
    ./librewolf
    ./nix
    ./rust
    ./starship
    ./sql
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
      gpustat
      iftop
      iotop
      jq
      lsof
      ltrace
      mtr
      pciutils
      ripgrep
      tree
      unzip
      usbutils
      zip
    ];
  };

  programs.home-manager.enable = true;

  xdg = {
    enable = true;
    mimeApps.enable = true;

    portal = {
      enable = true;
      config.common.default = "kde";
      extraPortals = [ pkgs.xdg-desktop-portal-kde ];
    };
  };

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
