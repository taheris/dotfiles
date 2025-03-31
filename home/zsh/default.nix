{ config, pkgs, ... }:

{
  imports = [
    ./alias.nix
    ./functions.nix
  ];

  home.packages = with pkgs; [
    aider-chat
    bat
    carapace
    expect
    kubectl
    vivid
    zsh-completions
  ];

  home.sessionVariables = {
    DIRENV_WARN_TIMEOUT = "30s";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;

    defaultOptions = [
      "--preview='bat --color=always {}'"
      "--multi"
      "--layout=reverse-list"
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    autocd = true;
    defaultKeymap = "emacs";
    syntaxHighlighting.enable = true;

    initExtraFirst = ''
      unset zle_bracketed_paste
    '';

    initExtra = ''
      # env secrets
      export ANTHROPIC_API_KEY="$(cat ${config.sops.secrets.anthropic.path})"
      export GEMINI_API_KEY="$(cat ${config.sops.secrets.gemini.path})"
      export OPENAI_API_KEY="$(cat ${config.sops.secrets.openai.path})"

      # env misc
      export FZF_CTRL_R_OPTS="--preview= --layout=default"
      export LS_COLORS=$(vivid generate tokyonight-night)
      export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"

      # case-insensitive completion
      zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

      # carapace
      zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
      source <(carapace _carapace)

      # fzf
      eval "$(fzf --zsh)"

      # kubernetes
      source <(kubectl completion zsh)

      # starship
      eval "$(starship init zsh)"
    '';
  };
}
