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
      apiKeyHelper = "cat ${config.sops.secrets.anthropic.path}";
    };
  };
}
