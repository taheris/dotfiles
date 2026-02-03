{
  host,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkForce
    mkIf
    mkMerge
    optionals
    ;
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (host) hasLinuxBuilder;

  packages = with pkgs; [
    claude-code-acp
    spec-kit
  ];

  # Packages that require an aarch64-linux builder when on aarch64-darwin
  linuxBuilderPackages = with pkgs; [
    beads
    wrapix-builder
    wrapix-notifyd
  ];

  darwinPackages = with pkgs; [
    container
    terminal-notifier
  ];

  linuxPackages = with pkgs; [
    libnotify
  ];

in
{
  home.packages = mkMerge [
    packages
    (optionals hasLinuxBuilder linuxBuilderPackages)
    (mkIf isDarwin darwinPackages)
    (mkIf isLinux linuxPackages)
  ];

  launchd.agents = {
    sops-nix = mkIf isDarwin {
      enable = true;
      config = {
        EnvironmentVariables = {
          PATH = mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    };

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
      model = "claude-opus-4-5-20251101";
      enableAllProjectMcpServers = false;
      includeCoAuthoredBy = false;

      env = {
        ANTHROPIC_MODEL = "opus";
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

}
