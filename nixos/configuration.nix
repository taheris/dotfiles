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
      vim
      wget
    ];
  };

  i18n.defaultLocale = "en_GB.utf8";
  time.timeZone = "Europe/Lisbon";

  networking = {
    networkmanager.enable = true;
    hostName = host.name;
  };

  nix = {
    nixPath = [ "/etc/nix/path" ];
    registry = (mapAttrs (_: flake: { inherit flake; })) ((filterAttrs (_: isType "flake")) inputs);
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
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
    ssh = {
      startAgent = true;
      enableAskPassword = true;
      askPassword = "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
    };

    zsh.enable = true;
  };

  security = {
    pam.services = {
      login.gnupg = {
        enable = true;
        noAutostart = true;
        storeOnly = true;
      };

      sddm.gnupg = {
        enable = true;
        noAutostart = true;
        storeOnly = true;
      };

      sddm.kwallet.enable = true;
    };

    sudo.wheelNeedsPassword = false;
  };

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    flatpak.enable = true;

    ollama = {
      enable = true;
      acceleration = "cuda";

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
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
    };
  };

  users.users = {
    ${host.user} = {
      isNormalUser = true;
      extraGroups = [
        "uinput"
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

  systemd.services = {
    systemd-machine-id-commit.enable = true;
  };

  system.stateVersion = "24.11";
}
