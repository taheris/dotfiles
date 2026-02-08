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
    watch
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
    ./desktop
    ./dotfile
    ./emacs
    ./flatpak
    ./font
    ./gpg
    ./git
    ./input
    ./librewolf
    ./nix
    ./python
    ./rust
    ./secrets
    ./starship
    ./stylix
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

    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";
}
