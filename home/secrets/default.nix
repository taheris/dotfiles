{
  inputs,
  config,
  pkgs,
  ...
}:

let
  inherit (builtins) toString;

in
{
  home.packages = with pkgs; [
    sops
  ];

  sops = {
    defaultSopsFile = "${toString inputs.secrets}/sops/secrets.yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      libera = { };
      "llm/anthropic" = { };
      "llm/cerebras" = { };
      "llm/gemini" = { };
      "llm/mistral" = { };
      "llm/openai" = { };
      "llm/zai" = { };
    };
  };
}
