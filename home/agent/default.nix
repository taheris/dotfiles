{ pkgs, ... }:

{
  home.packages = with pkgs; [
    claude-code-acp
    spec-kit
  ];

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
        CLAUDE_CODE_ENABLE_TELEMETRY = "0";
      };

      permissions = {
        defaultMode = "acceptEdits";
        disableBypassPermissionsMode = "disable";

        allow = [
          "Bash(cargo check:*)"
          "Bash(cargo build:*)"
          "Bash(cargo test:*)"
          "Bash(bd:*)"
          "Bash(find:*)"
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
