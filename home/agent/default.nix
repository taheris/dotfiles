{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkForce mkIf mkMerge;
  inherit (pkgs.stdenv) isDarwin;

  packages = with pkgs; [
    beads
    beads-viewer
    claude-code-acp
    spec-kit
  ];

  darwinPackages = with pkgs; [
    container
    terminal-notifier
  ];

in
{
  home.packages = mkMerge [
    packages
    (mkIf isDarwin darwinPackages)
  ];

  launchd.agents.sops-nix = mkIf isDarwin {
    enable = true;
    config = {
      EnvironmentVariables = {
        PATH = mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
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
        ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-5-20251101";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-opus-4-5-20251101";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-sonnet-4-5-20250929";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
        DISABLE_AUTOUPDATER = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_TELEMETRY = "1";
      };

      hooks = mkIf isDarwin {
        Notification = [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = "terminal-notifier -title 'Claude Code 🔔' -message 'Awaiting input...'";
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
}
