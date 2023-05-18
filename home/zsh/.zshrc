# Executes commands at the start of an interactive session.

# source custom files
for config_file (${HOME}/.zsh/*.zsh) source ${config_file}

# set keybindings
set -o emacs

# set terminal options
bindkey -e
bindkey "\eh" backward-kill-word
setopt autocd extendedglob nomatch notify

# set path
path=(
  /opt/homebrew/{bin,sbin}
  /opt/homebrew/opt/{emacs-mac,fzf,gettext,llvm,openssl@1.1,sqlite}/bin
  ~/{.cargo,.cabal}/bin
  ~/.dotnet/tools
  ~/bin
  $path
)

# zsh completions
fpath=(
  /opt/homebrew/share/zsh-completions
  /opt/homebrew/share/zsh/site-functions
  ~/.rustup/toolchains/stable-x86_64-apple-darwin/share/zsh/site-functions
  $fpath
)

# completions
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -Uz compinit && compinit

# set up kubernetes
source <(kubectl completion zsh)

# set up fzf
[[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null
source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"

# set up starship
eval "$(starship init zsh)"
