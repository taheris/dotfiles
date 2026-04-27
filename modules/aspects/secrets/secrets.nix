{ inputs, ... }:
{
  my.secrets.homeManager =
    { config, pkgs, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      home.packages = [ pkgs.sops ];

      sops = {
        defaultSopsFile = "${toString inputs.secrets}/sops/secrets.yaml";
        age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

        secrets = {
          "libera" = { };
          "llm/anthropic/api" = { };
          "llm/anthropic/oauth" = { };
          "llm/cerebras" = { };
          "llm/gemini" = { };
          "llm/mistral" = { };
          "llm/openai" = { };
          "llm/zai" = { };
        };
      };
    };
}
