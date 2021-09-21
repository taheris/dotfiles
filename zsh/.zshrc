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
  /usr/local/opt/{emacs-plus@28,gettext,llvm,mysql-client,openssl@1.1,sqlite}/bin
  ~/{.cargo,.cabal,.krew}/bin
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
zstyle :compinstall filename '/Users/shaun/.zshrc'
autoload -Uz compinit
compinit

# set up kubernetes
source <(kubectl completion zsh)

# set up zaw
source ~/src/github.com/zsh-users/zaw/zaw.zsh
bindkey '^R' zaw-history
bindkey -M filterselect '^J' down-line-or-history
bindkey -M filterselect '^K' up-line-or-history
bindkey -M filterselect '^E' accept-search
zstyle ':filter-select:highlight' matched fg=green
zstyle ':filter-select' max-lines 8
zstyle ':filter-select' case-insensitive yes
zstyle ':filter-select' extended-search yes

# set up starship
eval "$(starship init zsh)"
