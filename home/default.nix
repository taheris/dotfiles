{
  lib,
  pkgs,
  host,
  ...
}:

let
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv) isDarwin isLinux;

  packages = with pkgs; [
    btop
    docker-compose
    dnsutils
    fd
    file
    gnumake
    iftop
    jq
    lsof
    mtr
    pciutils
    pv
    ripgrep
    tree
    unzip
    yt-dlp
    zip
  ];

  linuxPackages = with pkgs; [
    dmidecode
    easyeffects
    ethtool
    gpustat
    iotop
    keyd
    ltrace
    pulseaudio
    texlive.combined.scheme-full
    tws
    usbutils
    wl-clipboard
  ];

in
{
  imports = [
    ./alacritty
    ./agent
    ./dotfile
    ./emacs
    ./flatpak
    ./font
    ./gpg
    ./git
    ./input
    ./librewolf
    ./nix
    ./plasma
    ./python
    ./rust
    ./secrets
    ./starship
    ./sql
    ./tmux
    ./vim
    ./zsh
  ];

  home = {
    username = host.user;
    homeDirectory = mkMerge [
      (mkIf isLinux "/home/${host.user}")
      (mkIf isDarwin "/Users/${host.user}")
    ];

    packages = mkMerge [
      packages
      (mkIf isLinux linuxPackages)
    ];
  };

  programs.home-manager.enable = true;

  xdg = mkIf isLinux {
    enable = true;
    mimeApps.enable = true;

    portal = {
      enable = true;
      config.common.default = "kde";
      extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    };
  };

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
