{ inputs, ... }:

{
  my.darwin =
    { host, ... }:
    {
      homeManager = {
        targets.darwin = {
          copyApps.enable = false;
          linkApps.enable = true;
        };
      };

      darwin =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          inherit (lib) mkBefore mkForce optionals;

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

          tailscaleEnv = pkgs.writeText "tailscaled-env.txt" ''
            TS_NO_LOGS_NO_SUPPORT=true
          '';

          nixBuilderProbe = pkgs.writeShellScript "nix-builder-probe" ''
            host="$1"
            port="$2"
            cache="''${TMPDIR:-/tmp}/nix-ssh-probe-$host"

            if [ -f "$cache" ]; then
              age=$(( $(date +%s) - $(stat -f %m "$cache" 2>/dev/null || echo 0) ))
              if [ "$age" -lt 300 ]; then
                echo "nix-builder-probe: $host is unreachable (cached)" >&2
                exit 1
              fi
              rm -f "$cache"
            fi

            if ! ${pkgs.coreutils}/bin/timeout 5 /usr/bin/nc -z "$host" "$port" 2>/dev/null; then
              touch "$cache"
              echo "nix-builder-probe: $host is unreachable" >&2
              exec cat /dev/null
            fi

            exec /usr/bin/nc "$host" "$port"
          '';
        in
        {
          environment = {
            etc = {
              "ssh/ssh_config.d/100-nix-builder.conf".text = ''
                Host nix
                  ProxyCommand ${nixBuilderProbe} %h %p
              '';

              "ssh/ssh_config.d/100-wrapix-builder.conf".text = ''
                Host wrapix-builder
                  Hostname localhost
                  Port 2222
                  User builder
                  HostKeyAlias wrapix-builder
                  IdentityFile /etc/nix/wrapix_builder_ed25519
              '';

              "tailscale/tailscaled-env.txt".source = tailscaleEnv;
            };

            systemPackages = with pkgs; [
              coreutils
              curl
              dockerCompat
              wget
            ];

            systemPath = mkBefore [
              "/Library/TeX/texbin"
            ];

            variables = {
              LANG = "en_GB.UTF-8";
            };
          };

          homebrew = {
            enable = true;

            brews = [
              "pam-reattach"
              "podman"
              "podman-compose"
            ];

            casks = [
              "alacritty"
              "bazecor"
              "bettertouchtool"
              "calibre"
              "cookie"
              "discord"
              "gpg-suite"
              "ibkr"
              "karabiner-elements"
              "keepassxc"
              "ledger-wallet"
              "librewolf"
              "little-snitch"
              "mactex"
              "mate-translate"
              "micro-snitch"
              "omniwm"
              "podman-desktop"
              "slack"
              "steam"
              "tailscale-app"
              "tidal"
              "trader-workstation"
              "ungoogled-chromium"
              "vlc"
              "wireshark-app"
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

            taps = [
              "BarutSRB/tap"
            ];
          };

          launchd = {
            daemons = {
              linux-builder.serviceConfig = {
                RunAtLoad = mkForce false;
                KeepAlive = mkForce false;
              };
            };

            user.agents.omniwm = {
              serviceConfig = {
                Label = "com.barutsrb.omniwm";
                ProgramArguments = [
                  "/usr/bin/open"
                  "-a"
                  "OmniWM"
                ];
                RunAtLoad = false;
                KeepAlive = false;
              };
            };
          };

          nix = {
            enable = true;
            gc.automatic = true;
            optimise.automatic = true;

            buildMachines = optionals host.hasLinuxBuilder [
              {
                hostName = "nix";
                maxJobs = 8;
                sshUser = host.user;
                sshKey = "/etc/nix/nix_builder_key";
                systems = [
                  "aarch64-linux"
                  "x86_64-linux"
                ];
                supportedFeatures = [
                  "benchmark"
                  "big-parallel"
                  "kvm"
                  "nixos-test"
                ];
              }
            ];

            linux-builder = {
              enable = true;
              maxJobs = 4;
              supportedFeatures = [ ];

              config = {
                virtualisation = {
                  cores = 6;
                  darwin-builder = {
                    diskSize = 40 * 1024;
                    memorySize = 8 * 1024;
                  };
                };
              };
            };

            settings = {
              download-buffer-size = 500 * 1024 * 1024;
              experimental-features = "nix-command flakes";
              substituters = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
              ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
              trusted-users = [
                "root"
                "@admin"
              ];
            };
          };

          nixpkgs.hostPlatform = host.system;

          programs.zsh = {
            enable = true;

            shellInit = ''
              eval "$(${config.homebrew.prefix}/bin/brew shellenv)"
            '';
          };

          system = {
            configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
            primaryUser = host.user;

            activationScripts.tailscaleEnv.text = ''
              install -d -o root -g wheel -m 0755 /private/var/root/Library/Containers/io.tailscale.ipn.macsys.network-extension/Data
              install -m 0644 ${tailscaleEnv} /private/var/root/Library/Containers/io.tailscale.ipn.macsys.network-extension/Data/tailscaled-env.txt
            '';

            defaults = {
              NSGlobalDomain = {
                AppleICUForce24HourTime = true;
                AppleMeasurementUnits = "Centimeters";
                AppleMetricUnits = 1;
                ApplePressAndHoldEnabled = false;
                AppleScrollerPagingBehavior = true;
                AppleShowAllExtensions = true;
                AppleShowScrollBars = "WhenScrolling";
                AppleTemperatureUnit = "Celsius";
                InitialKeyRepeat = 15;
                KeyRepeat = 2;
                NSAutomaticCapitalizationEnabled = false;
                NSAutomaticDashSubstitutionEnabled = false;
                NSAutomaticInlinePredictionEnabled = false;
                NSAutomaticPeriodSubstitutionEnabled = false;
                NSAutomaticQuoteSubstitutionEnabled = false;
                NSAutomaticSpellingCorrectionEnabled = false;
                NSDocumentSaveNewDocumentsToCloud = false;
                NSNavPanelExpandedStateForSaveMode = true;
                NSNavPanelExpandedStateForSaveMode2 = true;
                NSTextShowsControlCharacters = true;
                "com.apple.mouse.tapBehavior" = 1;
                "com.apple.sound.beep.feedback" = 0;
                "com.apple.sound.beep.volume" = 0.0;
                "com.apple.trackpad.scaling" = 3.0;
              };

              WindowManager = {
                AutoHide = true;
                EnableStandardClickToShowDesktop = false;
              };

              controlcenter = {
                BatteryShowPercentage = true;
                Sound = true;
              };

              dock = {
                autohide = true;
                autohide-time-modifier = 0.5;
                expose-animation-duration = 0.0;
                mineffect = "scale";
                mru-spaces = false;
                show-recents = false;
                tilesize = 44;
                wvous-br-corner = 1;
              };

              finder = {
                AppleShowAllExtensions = true;
                FXPreferredViewStyle = "clmv";
                NewWindowTarget = "Home";
                _FXSortFoldersFirst = true;
              };

              loginwindow.GuestEnabled = false;
              magicmouse.MouseButtonMode = "TwoButton";

              menuExtraClock = {
                Show24Hour = true;
                ShowDayOfMonth = true;
                ShowDayOfWeek = true;
              };

              screencapture.include-date = false;
              screensaver.askForPasswordDelay = 5;

              trackpad = {
                ActuationStrength = 0;
                Clicking = true;
                FirstClickThreshold = 0;
                SecondClickThreshold = 0;
                TrackpadRightClick = true;
                TrackpadThreeFingerTapGesture = 0;
              };

              universalaccess.reduceMotion = true;
            };

            patches = [
              (pkgs.writeText "pam_tid.patch" ''
                --- /etc/pam.d/sudo 2024-11-01 22:03:50
                +++ /etc/pam.d/sudo 2024-11-01 22:03:54
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
        };
    };
}
