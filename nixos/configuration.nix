{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mapAttrs'
    mkAfter
    isType
    ;

in
{
  imports = [ ./hardware-configuration.nix ];

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

    sessionVariables = {
      SSH_ASKPASS_REQUIRE = "prefer";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    };

    systemPackages = with pkgs; [
      curl
      pam_u2f
      vim
      wget
    ];
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
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
    hostName = host.name;
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

  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = host.system;

    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
    ];
  };

  programs = {
    gamemode.enable = true;

    niri = {
      enable = true;
      package = inputs.niri.packages.${host.system}.niri-unstable;
    };

    ssh.startAgent = false;
    zsh.enable = true;
  };

  security = {
    pam.services = {
      login.gnupg = {
        enable = true;
        noAutostart = true;
        storeOnly = true;
      };

      sudo.u2fAuth = true;
    };

    rtkit.enable = true;
  };

  services = {
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    flatpak.enable = true;

    interception-tools = {
      enable = true;
      udevmonConfig = ''
        - JOB: |
            ${pkgs.interception-tools}/bin/intercept -g $DEVNODE | \
            ${pkgs.intercept-fn-keys}/bin/intercept | \
            ${pkgs.interception-tools}/bin/uinput -d $DEVNODE
          DEVICE:
            NAME: "DYGMA DEFY Keyboard"
            EVENTS:
              EV_KEY: [KEY_F17, KEY_F18]
      '';
    };

    ollama = {
      enable = true;
      #acceleration = "cuda";

      environmentVariables = {
        CUDA_ERROR_LEVEL = "50";
        OLLAMA_FLASH_ATTENTION = "True";
        OLLAMA_KEEP_ALIVE = "30m";
      };
    };

    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    solaar = {
      enable = true;
      extraArgs = "--restart-on-wake-up";
    };

    tailscale = {
      enable = true;
    };

    udev.packages = [
      (pkgs.runCommand "custom-udev-rules" { } ''
        mkdir -p $out/lib/udev/rules.d

        cat > $out/lib/udev/rules.d/99-logitech-solaar.rules << EOF
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", TAG+="uaccess"
        SUBSYSTEM=="hidraw", KERNELS=="0005:046D:*", TAG+="uaccess"
        EOF

        cat > $out/lib/udev/rules.d/99-dygma-bazecor.rules << EOF
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2201", MODE="0666"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2200", MODE="0666"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="35ef", MODE="0666"
        KERNEL=="hidraw*", ATTRS{idVendor}=="35ef", MODE="0666"
        EOF
      '')
    ];

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";

    fonts = {
      monospace = {
        name = "Noto Sans Mono";
        package = pkgs.noto-fonts;
      };
      serif = {
        name = "Noto Serif";
        package = pkgs.noto-fonts;
      };
      sansSerif = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
      };
      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-color-emoji;
      };
    };

    image = pkgs.fetchurl {
      url = "https://images.unsplash.com/photo-1729614499383-756f6e0e4d80";
      sha256 = "05c2rx7i7k7w87dnzjcn1znbvj00q21a956kmqs4mfw558rxnmfw";
      name = "wallpaper.jpg";
    };
  };

  users.users = {
    ${host.user} = {
      isNormalUser = true;
      extraGroups = [
        "gamemode"
        "input"
        "wheel"
      ];
      shell = pkgs.zsh;
    };
  };

  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings = {
        engine.compose_warning_logs = false;
      };
    };

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  systemd = {
    services = {
      systemd-machine-id-commit.enable = true;
      tailscaled.serviceConfig.Environment = mkAfter [ "TS_NO_LOGS_NO_SUPPORT=true" ];
    };

    user.services.niri-flake-polkit.enable = false;
  };

  system.stateVersion = "24.11";
}
