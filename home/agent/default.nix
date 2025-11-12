{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    claude-code-acp
  ];

  programs.claude-code = {
    enable = true;

    settings = {
      apiKeyHelper = "cat ${config.sops.secrets."llm/zai".path}";
      model = "GLM-4.6";
      enableAllProjectMcpServers = false;
      includeCoAuthoredBy = false;

      env = {
        ANTHROPIC_API_KEY_USE = "https://docs.z.ai/scenario-example/develop-tools/claude";
        ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
        ANTHROPIC_MODEL = "GLM-4.6";
        ANTHROPIC_SMALL_FAST_MODEL = "GLM-4.5-Air";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "GLM-4.6";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "GLM-4.6";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "GLM-4.5-Air";
      };

      permissions = {
        defaultMode = "acceptEdits";
        disableBypassPermissionsMode = "disable";

        allow = [
          "Bash(cargo check:*)"
          "Bash(cargo build:*)"
          "Bash(cargo test:*)"
          "Bash(find:*)"
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(git status:*)"
          "Bash(ls:*)"
          "Bash(make:*)"
          "Bash(nix run .)"
          "Bash(yarn test)"

          "Read(~/.claude/plugins/cache/superpowers/skills/*)"

          "WebSearch"
          "WebFetch(domain:crates.io)"
          "WebFetch(domain:developer.mozilla.org)"
          "WebFetch(domain:docs.rs)"
          "WebFetch(domain:github.com)"
          "WebFetch(domain:nix-community.github.io)"
        ];
        ask = [ ];
        deny = [
          "Bash(curl:*)"
          "Bash(git:*)"
          "Bash(su:*)"
          "Bash(sudo:*)"
          "Bash(home-manager switch:*)"
          "Bash(nc:*)"
          "Bash(nixos-rebuild switch:*)"
          "Bash(rsync:*)"
          "Bash(ssh:*)"
          "Bash(scp:*)"
          "Bash(wget:*)"

          "Read(~/.aws)"
          "Read(~/.authinfo)"
          "Read(~/.config/sops)"
          "Read(~/.config/sops-nix)"
          "Read(~/.gnupg)"
          "Read(~/.ssh)"

          "Read(./.env)"
          "Read(./.envrc)"
          "Read(./.direnv)"
        ];
      };

      statusLine = {
        command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')]  $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
        padding = 0;
        type = "command";
      };

      modelPreferences = {
        coding = "GLM-4.6";
        debugging = "GLM-4.6";
        documentation = "GLM-4.6";
        fileSearch = "GLM-4.5-Air";
        syntaxCheck = "GLM-4.5-Air";
        quickRefactor = "GLM-4.5-Air";
      };
    };
  };
}
