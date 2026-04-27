{ ... }:

{
  my.base.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
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

      programs.home-manager.enable = true;

      systemd.user.startServices = "sd-switch";
    };
}
