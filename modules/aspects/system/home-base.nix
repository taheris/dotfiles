{ ... }:
{
  my.home-base.homeManager =
    { lib, pkgs, ... }:
    let
      inherit (lib) mkIf;
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
        mdcat
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
      home.packages = packages ++ (if isLinux then linuxPackages else [ ]);

      programs.home-manager.enable = true;
      systemd.user.startServices = "sd-switch";

      targets.darwin = mkIf isDarwin {
        copyApps.enable = false;
        linkApps.enable = true;
      };
    };
}
