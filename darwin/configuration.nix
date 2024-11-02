{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkForce
    ;

in
{
  environment = {
    systemPackages = with pkgs; [
      coreutils
    ];
  };

  fonts.packages = with pkgs; [
    julia-mono
    libre-baskerville
  ];

  homebrew = {
    enable = true;

    brews = [
      "pam-reattach"
    ];

    casks = [
      "alacritty"
      "bettertouchtool"
      "calibre"
      "cookie"
      "discord"
      "eloston-chromium"
      "gpg-suite"
      "karabiner-elements"
      "keepassxc"
      "ledger-live"
      "librewolf"
      "little-snitch"
      "mactex"
      "micro-snitch"
      "slack"
      "tailscale"
      "tidal"
      "wireshark"
    ];

    masApps = {
      Bitwarden = 1352778147;
    };

    onActivation = {
      cleanup = "zap";
      extraFlags = [ "--verbose" ];
    };
  };

  nix = {
    gc.automatic = true;
    optimise.automatic = true;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "@admin"
      ];
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = "aarch64-darwin";

    overlays = [ ];
  };

  programs = {
    zsh = {
      enable = true;

      shellInit = ''
        eval "$(${config.homebrew.brewPrefix}/brew shellenv)"
      '';

      variables = {
        LANG = "en_US.UTF-8";
      };
    };
  };

  services = {
    nix-daemon.enable = true;
  };

  system = {
    stateVersion = 5;
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

    defaults = {
      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        ApplePressAndHoldEnabled = false;
        AppleScrollerPagingBehavior = true;
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "WhenScrolling";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSDocumentSaveNewDocumentsToCloud = false;
      };
      loginwindow.GuestEnabled = false;
      finder.FXPreferredViewStyle = "clmv";
    };

    patches = [
      (pkgs.writeText "pam_tid.patch" ''
        --- /etc/pam.d/sudo	2024-11-01 22:03:50
        +++ /etc/pam.d/sudo	2024-11-01 22:03:54
        @@ -1,4 +1,6 @@
         # sudo: auth account password session
        +auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
        +auth       sufficient     pam_tid.so
         auth       include        sudo_local
         auth       sufficient     pam_smartcard.so
         auth       required       pam_opendirectory.so
      '')
    ];
  };

  users.users.shaun = {
    name = "shaun";
    home = "/Users/shaun";
  };
}
