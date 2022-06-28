# Executes commands at the start of an interactive session.

# source custom files
for config_file ($HOME/.zsh/*.zsh) source $config_file

# set keybindings
set -o emacs

# set terminal options
bindkey -e
bindkey "\eh" backward-kill-word
setopt autocd extendedglob nomatch notify

# set path
path=(
  /usr/local/sbin
  /usr/local/opt/{emacs-plus@28,fzf,gettext,llvm,mysql-client,openssl@1.1,sqlite}/bin
  ~/{.cargo,.cabal,.krew}/bin
  ~/bin
  $path
)

# zsh completions
fpath=(
  /usr/local/share/zsh-completions
  /usr/local/share/zsh/site-functions
  ~/.rustup/toolchains/stable-x86_64-apple-darwin/share/zsh/site-functions
  $fpath
)

# completions
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -Uz compinit && compinit

# set up kubernetes
source <(kubectl completion zsh)

# set up fzf
[[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null
source "/usr/local/opt/fzf/shell/key-bindings.zsh"

# set up starship
eval "$(starship init zsh)"
