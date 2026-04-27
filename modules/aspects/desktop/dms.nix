{ inputs, ... }:
{
  my.dms =
    { host, ... }:
    {
      homeManager =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          inherit (lib) mkIf;
          inherit (pkgs.stdenv) isLinux;
        in
        mkIf isLinux {
          imports = [ inputs.dms.homeModules.dank-material-shell ];

          home.packages = with pkgs; [
            catppuccin-gtk
            inter
            tela-icon-theme
          ];

          programs.dank-material-shell = {
            enable = true;
            managePluginSettings = true;

            niri = {
              enableSpawn = false;
              enableKeybinds = false;
            };

            settings = {
              # Theme
              currentThemeCategory = "registry";
              registryThemeVariants = {
                catppuccin = {
                  flavor = "mocha";
                  accent = "lavender";
                };
                flexoki = "orange";
                gruvboxMaterial = "medium";
                everforest = "hard";
              };

              # Layout
              cornerRadius = 4;
              niriLayoutGapsOverride = 6;
              niriLayoutRadiusOverride = 4;
              niriLayoutBorderSize = 3;

              # Clock
              use24HourClock = true;

              # Cursor
              cursorSettings = {
                theme = "System Default";
                size = 24;
                niri.hideWhenTyping = true;
              };

              # Sounds
              soundNewNotification = false;

              # Music
              audioVisualizerEnabled = true;
              waveProgressEnabled = true;
              scrollTitleEnabled = true;
              audioScrollMode = "volume";

              # Launcher
              launcherLogoMode = "os";
              appLauncherViewMode = "grid";
              spotlightCloseNiriOverview = true;
              niriOverviewOverlayEnabled = true;

              # Notifications
              notificationRules = [
                {
                  enabled = true;
                  field = "desktopEntry";
                  pattern = "com.mastermindzh.tidal-hifi";
                  matchType = "exact";
                  action = "mute";
                  urgency = "default";
                }
              ];

              # Network
              networkPreference = "ethernet";

              # Bar widgets
              runningAppsCompactMode = true;
              showGpuTemp = true;

              # Dock
              showDock = false;

              # Power
              powerMenuDefaultAction = "hibernate";
              acMonitorTimeout = 300;
              acLockTimeout = 900;
              acSuspendTimeout = 900;
              lockBeforeSuspend = true;
              fadeToLockEnabled = true;
              fadeToDpmsEnabled = true;

              # Display
              niriOutputSettings = {
                "DP-5".disabled = true;
              };

              # Bar
              barConfigs = [
                {
                  id = "default";
                  name = "Main Bar";
                  enabled = true;
                  position = 1;
                  screenPreferences = [ "all" ];
                  showOnLastDisplay = true;
                  autoHide = true;
                  autoHideDelay = 250;
                  openOnOverview = true;
                  leftWidgets = [
                    "launcherButton"
                    "workspaceSwitcher"
                    "focusedWindow"
                  ];
                  centerWidgets = [
                    {
                      id = "music";
                      enabled = true;
                      mediaSize = 3;
                    }
                    "clock"
                    "weather"
                  ];
                  rightWidgets = [
                    {
                      id = "network_speed_monitor";
                      enabled = true;
                    }
                    {
                      id = "cpuUsage";
                      enabled = true;
                    }
                    {
                      id = "memUsage";
                      enabled = true;
                    }
                    {
                      id = "cpuTemp";
                      enabled = true;
                      minimumWidth = true;
                    }
                    {
                      id = "clipboard";
                      enabled = true;
                    }
                    {
                      id = "systemTray";
                      enabled = true;
                    }
                    {
                      id = "controlCenterButton";
                      enabled = true;
                      showAudioPercent = false;
                      showMicIcon = true;
                      showMicPercent = false;
                    }
                    {
                      id = "notificationButton";
                      enabled = true;
                    }
                    {
                      id = "privacyIndicator";
                      enabled = true;
                    }
                  ];
                  spacing = 4;
                  innerPadding = 4;
                  bottomGap = 0;
                  transparency = 1;
                  widgetTransparency = 1;
                }
              ];
            };

            session = {
              wallpaperPath = toString config.stylix.image;
              weatherCoordinates = "38.72509,-9.1498";
              weatherLocation = "Lisbon";
            };

            plugins = {
              calculator.enable = true;
              dockerManager.enable = true;

              mediaPlayer = {
                enable = true;
                settings.preferredSource = "tidal";
              };
            };
          };

          systemd.user.services.dms = {
            Unit = {
              Description = "Dank Material Shell";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${inputs.dms.packages.${host.system}.default}/bin/dms run";
              Restart = "on-failure";
              RestartSec = 2;
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };
        };
    };
}
