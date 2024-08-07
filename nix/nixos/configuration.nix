{
  inputs,
  outputs,
  lib,
  config,
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
  imports = [ ./hardware-configuration.nix ];

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  environment = {
    etc = mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry;

    pathsToLink = [ "/share/zsh" ];

    systemPackages = with pkgs; [
      curl
      git
      kdePackages.discover
      kdePackages.plasma-browser-integration
      vim
      wget
    ];
  };

  fonts.packages = with pkgs; [
    julia-mono
    libre-baskerville
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Lisbon";

  networking = {
    hostName = "nix";
    networkmanager.enable = true;
  };

  nix = {
    nixPath = [ "/etc/nix/path" ];
    registry = (mapAttrs (_: flake: { inherit flake; })) ((filterAttrs (_: isType "flake")) inputs);
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "shaun"
      ];
    };
  };

  nixpkgs = {
    config.allowUnfree = true;

    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
    ];
  };

  programs.zsh.enable = true;

  security = {
    sudo.wheelNeedsPassword = false;
  };

  services = {
    desktopManager = {
      plasma6.enable = true;
    };

    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "shaun";
      sddm.wayland.enable = true;
    };

    flatpak.enable = true;

    ollama = {
      enable = true;
      host = "0.0.0.0";
      acceleration = "cuda";

      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "True";
        CUDA_ERROR_LEVEL = "50";
      };
    };

    postgresql = {
      enable = true;
      extraPlugins = [ pkgs.postgresqlPackages.pgvector ];

      settings = {
        log_connections = true;
        log_disconnections = true;
        log_statement = "all";
        logging_collector = true;
      };

      authentication = ''
        local  all  postgres  peer  map=eroot
      '';

      identMap = ''
        eroot  root      postgres
        eroot  postgres  postgres
      '';
    };

    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    tailscale = {
      enable = true;
    };

    xserver = {
      enable = true;
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
    };
  };

  users.users = {
    shaun = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
    };
  };

  virtualisation = {
    containers.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  system.stateVersion = "24.05";
}
