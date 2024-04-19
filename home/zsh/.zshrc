# Executes commands at the start of an interactive session.

# source custom files
for config_file (${HOME}/.zsh/*.zsh) source ${config_file}

# set keybindings
set -o emacs

# set terminal options
bindkey -e
bindkey "\eh" backward-kill-word
bindkey "^[[3~" delete-char
setopt autocd extendedglob nomatch notify

# set path
path=(
  #/opt/homebrew/{bin,sbin}
  #/opt/homebrew/opt/{emacs-mac,fzf,gettext,libpq,llvm,openssl@3,sqlite}/bin
  /usr/lib/rustup/bin
  ~/.config/emacs/bin
  ~/{.cargo,.cabal}/bin
  ~/.dotnet/tools
  ~/bin
  $path
)

# zsh completions
fpath=(
  #/opt/homebrew/share/zsh-completions
  #/opt/homebrew/share/zsh/site-functions
  ~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/share/zsh/site-functions
  $fpath
)

# completions
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -Uz compinit && compinit

# ssh-agent
[[ ! -f "${XDG_RUNTIME_DIR}/ssh-agent.env" ]] && ssh-agent > "${XDG_RUNTIME_DIR}/ssh-agent.env"
[[ ! -f "${SSH_AUTH_SOCK}" ]] && source "${XDG_RUNTIME_DIR}/ssh-agent.env" >/dev/null

# kubernetes
source <(kubectl completion zsh)

# fzf
eval "$(fzf --zsh)"

# starship
eval "$(starship init zsh)"

# carapace
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# direnv
eval "$(direnv hook zsh)"
source ~/.nix-profile/share/nix-direnv/direnvrc
