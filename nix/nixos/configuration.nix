{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  hostname,
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
        flakePaths = mapAttrs' flakePath config.nix.registry;
        flakePath = name: value: {
          name = "nix/path/${name}";
          value.source = value.flake;
        };
      in
      { machine-id.text = "${hostname}"; } // flakePaths;

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
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-extra
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Lisbon";

  networking = {
    networkmanager.enable = true;
    hostName = hostname;
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

    #searx = {
    #  enable = true;
    #  environmentFile = "/var/lib/secret/searx.env";

    #  settings = {
    #    server.port = 8080;
    #    server.secret_key = "@SEARX_SECRET_KEY@";
    #  };
    #};

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

  system.stateVersion = "24.05";
}
