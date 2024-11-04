{
  inputs,
  pkgs,
  config,
  host,
  ...
}:

let
  dockerCompat =
    pkgs.runCommand "${pkgs.podman.pname}-docker-compat-${pkgs.podman.version}"
      {
        inherit (pkgs.podman) meta;
        outputs = [
          "out"
          "man"
        ];
      }
      ''
        mkdir -p $out/bin
        ln -s ${pkgs.podman}/bin/podman $out/bin/docker

        mkdir -p $man/share/man/man1
        for f in ${pkgs.podman.man}/share/man/man1/*; do
          basename=$(basename $f | sed s/podman/docker/g)
          ln -s $f $man/share/man/man1/$basename
        done
      '';

in
{
  environment = {
    systemPackages = [
      pkgs.coreutils
      dockerCompat
    ];

    variables = {
      LANG = "en_GB.UTF-8";
    };
  };

  fonts.packages = with pkgs; [
    julia-mono
    libre-baskerville
  ];

  homebrew = {
    enable = true;

    brews = [
      "pam-reattach"
      "podman"
      "podman-compose"
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
      {
        name = "librewolf";
        args = {
          no_quarantine = true;
        };
      }
      "little-snitch"
      "mactex"
      "mate-translate"
      "micro-snitch"
      "podman-desktop"
      "slack"
      "tailscale"
      "tidal"
      "wireshark"
    ];

    masApps = {
      Bitwarden = 1352778147;
    };

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      extraFlags = [ "--verbose" ];
      upgrade = true;
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

  users.users.${host.user} = {
    name = "${host.user}";
    home = "/Users/${host.user}";
  };
}
