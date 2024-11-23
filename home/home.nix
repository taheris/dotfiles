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
    gnumake
    gnupg
    iftop
    jq
    lsof
    mtr
    mycli
    pciutils
    pv
    ripgrep
    tree
    unzip
    zip
  ];

  linuxPackages = with pkgs; [
    ethtool
    gpustat
    iotop
    ltrace
    usbutils
  ];

in
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
      extraPortals = [ pkgs.xdg-desktop-portal-kde ];
    };
  };

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
