{ lib, ... }:

{
  my.agent.homeManager =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf mkMerge optionals;
      inherit (pkgs.stdenv) isDarwin isLinux;
      inherit (pkgs.stdenv.hostPlatform) isAarch64;

      inherit (config.my) hasLinuxBuilder;

      packages = with pkgs; [
        beads
        loom
      ];

      darwinPackages =
        with pkgs;
        [
          terminal-notifier
        ]
        ++ optionals isAarch64 [
          container
        ];

      builderPackages = with pkgs; [
        wrix-builder
      ];

      linuxBuilderHostPackages = with pkgs; [
        wrix-notifyd
      ];

      linuxPackages = with pkgs; [
        libnotify
      ];

    in
    {
      home.packages = mkMerge [
        packages
        (mkIf isLinux builderPackages)
        (optionals (isLinux || (isDarwin && hasLinuxBuilder)) linuxBuilderHostPackages)
        (mkIf isDarwin darwinPackages)
        (mkIf isLinux linuxPackages)
      ];

      launchd.agents = {
        wrix-notifyd = mkIf (isDarwin && hasLinuxBuilder) {
          enable = true;
          config = {
            ProgramArguments = [ "${pkgs.wrix-notifyd}/bin/wrix-notifyd" ];
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "/tmp/wrix-notifyd.log";
            StandardErrorPath = "/tmp/wrix-notifyd.log";
          };
        };
      };

      programs.claude-code = {
        enable = true;

        settings = {
          model = "claude-opus-4-8";
          effortCalloutDismissed = true;
          enableAllProjectMcpServers = false;
          includeCoAuthoredBy = false;

          attribution = {
            commit = "";
            pr = "";
          };

          env = {
            ANTHROPIC_MODEL = "claude-opus-4-8";
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
            DISABLE_AUTOUPDATER = "1";
            DISABLE_ERROR_REPORTING = "1";
            DISABLE_TELEMETRY = "1";
          };

          hooks = {
            Notification = [
              {
                matcher = "*";
                hooks = [
                  {
                    type = "command";
                    command =
                      if isDarwin then
                        "terminal-notifier -title 'Claude Code 🔔' -message 'Awaiting input...'"
                      else
                        "notify-send 'Claude Code 🔔' 'Awaiting input...'";
                  }
                ];
              }
            ];
          };

          permissions = {
            defaultMode = "acceptEdits";
            allow = [
              "Bash(cargo check:*)"
              "Bash(cargo build:*)"
              "Bash(cargo test:*)"
              "Bash(bd:*)"
              "Bash(git diff:*)"
              "Bash(git log:*)"
              "Bash(git status:*)"
              "Bash(gt:*)"
              "Bash(ls:*)"
              "Bash(make:*)"
              "Bash(nix run .)"
              "Bash(yarn test)"

              "WebSearch"
            ];
            ask = [ ];
            deny = [
              "Bash(su:*)"
              "Bash(sudo:*)"
              "Bash(home-manager switch:*)"
              "Bash(nixos-rebuild switch:*)"

              "Read(~/.aws)"
              "Read(~/.authinfo)"
              "Read(~/.config/sops)"
              "Read(~/.config/sops-nix)"
              "Read(~/.gnupg)"
              "Read(~/.ssh)"

              "Read(~/**/.envrc)"
              "Read(~/**/.env)"
              "Read(~/**/.direnv)"
            ];
          };
        };
      };

      programs.codex = {
        enable = true;
      };

      systemd.user.services.wrix-notifyd = mkIf isLinux {
        Unit = {
          Description = "Wrix notification daemon";
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.wrix-notifyd}/bin/wrix-notifyd";
          Restart = "always";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
