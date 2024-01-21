# Defines environment variables.

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "${SHLVL}" -eq 1 && ! -o LOGIN ) && -s "${HOME}/.zprofile" ]]; then
  source "${HOME}/.zprofile"
fi

# misc
export CLOUDSDK_PYTHON_SITEPACKAGES=1
export DOCKER_SCAN_SUGGEST=false
export GOPATH=~
export GPG_TTY=$(tty)
export LESSHISTFILE=-
export LC_ALL=en_US.UTF-8
export MANPATH=${MANPATH}:/opt/homebrew/opt/gnu-tar/libexec/gnuman
export STARSHIP_CONFIG=~/.config/starship/config.toml

# homebrew
export HOMEBREW_NO_ANALYTICS=true
export HOMEBREW_NO_ENV_HINTS=true

# openssl
export OPENSSL_ROOT_DIR=/opt/homebrew/opt/openssl@3.1
export OPENSSL_INCLUDE_DIR=/opt/homebrew/opt/openssl@3.1/include
export OPENSSL_LIB_DIR=/opt/homebrew/opt/openssl@3.1/lib

# rust
export CARGO_HOME=~/.cargo
export RUSTC_WRAPPER=sccache

# java
export JAVA_HOME=/opt/homebrew/opt/openjdk

# gtags
export GTAGSCONF=/opt/homebrew/share/gtags/gtags.conf
export GTAGSLABEL=pygments

# fzf
export FZF_DEFAULT_OPTS='--height 40% --reverse'
. "${HOME}/.cargo/env"
