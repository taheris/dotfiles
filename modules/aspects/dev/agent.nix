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
        spec-kit
      ];

      darwinPackages =
        with pkgs;
        [
          terminal-notifier
        ]
        ++ optionals isAarch64 [
          container
        ];

      # Packages that require an aarch64-linux builder when on aarch64-darwin
      linuxBuilderPackages = with pkgs; [
        wrapix-builder
        wrapix-notifyd
      ];

      linuxPackages = with pkgs; [
        libnotify
      ];

    in
    {
      home.packages = mkMerge [
        packages
        (optionals (isLinux || hasLinuxBuilder) linuxBuilderPackages)
        (mkIf isDarwin darwinPackages)
        (mkIf isLinux linuxPackages)
      ];

      launchd.agents = {
        wrapix-notifyd = mkIf (isDarwin && hasLinuxBuilder) {
          enable = true;
          config = {
            ProgramArguments = [ "${pkgs.wrapix-notifyd}/bin/wrapix-notifyd" ];
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "/tmp/wrapix-notifyd.log";
            StandardErrorPath = "/tmp/wrapix-notifyd.log";
          };
        };
      };

      programs.claude-code = {
        enable = true;

        settings = {
          model = "claude-opus-4-6";
          effortCalloutDismissed = true;
          enableAllProjectMcpServers = false;
          includeCoAuthoredBy = false;

          attribution = {
            commit = "";
            pr = "";
          };

          env = {
            ANTHROPIC_MODEL = "claude-opus-4-6";
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

      systemd.user.services.wrapix-notifyd = mkIf isLinux {
        Unit = {
          Description = "Wrapix notification daemon";
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.wrapix-notifyd}/bin/wrapix-notifyd";
          Restart = "always";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
