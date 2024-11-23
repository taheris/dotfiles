# Dotfiles configured with nix

Run `make` to see a list of setup commands.

## Bootstrapping a new macOS host

1. Add a new host to `hosts.nix`.
2. Run `make set-hostname <name>` to set the hostname.
3. Run `make install-brew` to install homebrew.
4. Run `make install-nix` to install nix.
5. Run `make install-flake` to install the nix flake.
