{ pkgs, ... }:

{
  imports = [
    ./alias.nix
    ./functions.nix
  ];

  home.packages = with pkgs; [
    carapace
    expect
    fzf
    kubectl
  ];

  home.sessionVariables = {
    DIRENV_WARN_TIMEOUT = "30s";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;

    autocd = true;
    defaultKeymap = "emacs";
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    initExtraFirst = ''
      unset zle_bracketed_paste
    '';

    initExtra = ''
      # case-insensitive completion
      zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

      # carapace
      zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
      source <(carapace _carapace)

      # direnv
      eval "$(direnv hook zsh)"
      source ~/.nix-profile/share/nix-direnv/direnvrc

      # fzf
      eval "$(fzf --zsh)"

      # kubernetes
      source <(kubectl completion zsh)

      # starship
      eval "$(starship init zsh)"
    '';
  };
}
