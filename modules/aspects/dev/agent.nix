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
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
      inherit (pkgs.stdenv.hostPlatform) isAarch64;

      inherit (config.my) hasLinuxBuilder;

      packages = with pkgs; [
        beads
        loom
        wrix
        wrix-notify-host
        wrix-notifyd
        wrix-focus-notification
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

      linuxPackages = with pkgs; [
        libnotify
      ];

      codexNotify = pkgs.writeShellScript "codex-notify" ''
        # Codex appends the event as a JSON argument, not stdin.
        if ! ${pkgs.jq}/bin/jq -e '.type == "agent-turn-complete"' \
          <<< "''${1:-}" >/dev/null 2>&1; then
          exit 0
        fi

        # Origin is captured by the launcher, never by this callback.
        ${pkgs.wrix-notify-host}/bin/wrix-notify-host 'Codex' 'Turn complete. Awaiting input...' || :
      '';

      codexLauncher = pkgs.writeShellScriptBin "codex" ''
        exec ${pkgs.wrix}/bin/wrix notify run -- ${lib.getExe pkgs.codex} "$@"
      '';

      codexPackage = pkgs.symlinkJoin {
        name = "codex-wrix-${pkgs.codex.version}";
        inherit (pkgs.codex) version meta;
        paths = [ pkgs.codex ];
        postBuild = ''
          ln -sf ${codexLauncher}/bin/codex "$out/bin/codex"
        '';
      };

    in
    {
      home.packages = mkMerge [
        packages
        (mkIf (isDarwin && hasLinuxBuilder) builderPackages)
        (mkIf isDarwin darwinPackages)
        (mkIf isLinux linuxPackages)
      ];

      launchd.agents = {
        wrix-notifyd = mkIf isDarwin {
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
        package = codexPackage;
        # Preserve trusted projects and other settings written interactively by Codex.
        mutableSettings = true;
        settings = {
          notify = [ "${codexNotify}" ];
          # Completion uses the callback; retain terminal approval alerts.
          tui.notifications = [ "approval-requested" ];
        };
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
