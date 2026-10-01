{ inputs, ... }:

{
  my.linux.homeManager =
    { pkgs, ... }:
    {
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      home.packages = with pkgs; [
        dmidecode
        easyeffects
        ethtool
        gpustat
        iotop
        keyd
        ltrace
        pulseaudio
        texliveMedium
        usbutils
        wl-clipboard
      ];
    };

  my.linux.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        filterAttrs
        mapAttrs
        mapAttrs'
        isType
        ;
    in
    {
      console = {
        font = "Lat2-Terminus16";
        useXkbConfig = true;
      };

      environment = {
        etc =
          let
            flakePath = name: value: {
              name = "nix/path/${name}";
              value.source = value.flake;
            };
          in
          mapAttrs' flakePath config.nix.registry;

        pathsToLink = [ "/share/zsh" ];

        systemPackages = with pkgs; [
          curl
          mosh
          vim
          wget
        ];
      };

      i18n = {
        defaultLocale = "en_GB.UTF-8";
        supportedLocales = [
          "en_GB.UTF-8/UTF-8"
          "en_US.UTF-8/UTF-8"
        ];
      };

      networking = {
        networkmanager.enable = true;
        firewall.enable = true;
      };

      nix = {
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };

        registry = (mapAttrs (_: flake: { inherit flake; })) ((filterAttrs (_: isType "flake")) inputs);

        settings = {
          auto-optimise-store = true;
          experimental-features = [
            "flakes"
            "nix-command"
          ];
          nix-path = [ "/etc/nix/path" ];
          substituters = [
            "https://cache.nixos.org"
            "https://cache.nixos-cuda.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          ];
          trusted-users = [
            "root"
            "@wheel"
          ];
        };
      };

      programs = {
        gamemode.enable = true;
        zsh.enable = true;
      };

      systemd = {
        sleep.settings.Sleep.HibernateDelaySec = 60;
        services.systemd-machine-id-commit.enable = true;
      };

      time.timeZone = "Europe/Lisbon";
    };
}
