# Executes commands at login, pre-zshrc

export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'

export LESS='-F -g -i -M -R -S -w -X -z-4'

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER='open'
fi

if [[ -z "$LANG" ]]; then
  export LANG='en_US.UTF-8'
fi

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that Zsh searches for programs.
path=(
  /usr/local/{bin,sbin}
  $path
)
