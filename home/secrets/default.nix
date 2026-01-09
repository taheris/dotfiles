{
  inputs,
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sops
  ];

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
}
