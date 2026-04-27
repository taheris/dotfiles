{ inputs, ... }:
{
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

      time.timeZone = "Europe/Lisbon";

      networking = {
        networkmanager.enable = true;
        firewall.enable = true;
      };

      nix = {
        nixPath = [ "/etc/nix/path" ];
        registry = (mapAttrs (_: flake: { inherit flake; })) ((filterAttrs (_: isType "flake")) inputs);

        gc = {
          automatic = true;
          dates = "monthly";
        };

        settings = {
          auto-optimise-store = true;
          experimental-features = [
            "flakes"
            "nix-command"
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

      services.udev.packages = [
        (pkgs.runCommand "custom-udev-rules" { } ''
          mkdir -p $out/lib/udev/rules.d

          cat > $out/lib/udev/rules.d/99-logitech-hidpp.rules << EOF
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", TAG+="uaccess", MODE="0660", GROUP="input"
          SUBSYSTEM=="hidraw", KERNELS=="0005:046D:*", TAG+="uaccess", MODE="0660", GROUP="input"
          EOF

          cat > $out/lib/udev/rules.d/99-dygma-bazecor.rules << EOF
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2201", MODE="0666"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2200", MODE="0666"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="35ef", MODE="0666"
          KERNEL=="hidraw*", ATTRS{idVendor}=="35ef", MODE="0666"
          EOF

          cat > $out/lib/udev/rules.d/99-apple-display-backlight.rules << EOF
          SUBSYSTEM=="backlight", KERNEL=="apple_xdr_display", MODE="0664", GROUP="users"
          EOF
        '')
      ];

      systemd = {
        sleep.settings.Sleep.HibernateDelaySec = 60;
        services.systemd-machine-id-commit.enable = true;
      };
    };
}
