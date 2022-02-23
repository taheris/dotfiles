# Defines environment variables.

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "$HOME/.zprofile" ]]; then
  source "$HOME/.zprofile"
fi

# misc
export DOCKER_SCAN_SUGGEST=false
export GOPATH=~
export LC_ALL=en_US.UTF-8
export MANPATH=$MANPATH:/usr/local/opt/gnu-tar/libexec/gnuman
export STARSHIP_CONFIG=~/.config/starship/config.toml

# homebrew
export HOMEBREW_NO_ANALYTICS=true
export HOMEBREW_NO_ENV_HINTS=true

# openssl
export OPENSSL_ROOT_DIR=/usr/local/opt/openssl@1.1
export OPENSSL_INCLUDE_DIR=/usr/local/opt/openssl@1.1/include
export OPENSSL_LIB_DIR=/usr/local/opt/openssl@1.1/lib

# rust
export CARGO_HOME=~/.cargo
export RUSTC_WRAPPER=sccache

# jvm
export JAVA_HOME=/Library/Java/Home
export SBT_OPTS="-XX:MaxHeapSize=8G"

# gtags
export GTAGSCONF=/usr/local/share/gtags/gtags.conf
export GTAGSLABEL=pygments
