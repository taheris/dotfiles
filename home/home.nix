{
  lib,
  pkgs,
  host,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;

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
    homeDirectory = if isLinux then "/home/${host.user}" else "/Users/${host.user}";

    packages = packages ++ (if isLinux then linuxPackages else [ ]);
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
