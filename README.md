# Dotfiles configured with nix

Run `make` to see a list of setup commands.

## Bootstrapping a new NixOS host

1. Add a new host to `hosts.nix`.
2. Ensure `hardware-configuration.nix` is set up appropriately.
3. Run `make nixos-boot` to add a new boot configuration.
4. Reboot into the new system.
5. Run `make nixos-home` to install home-manger.

## Bootstrapping a new macOS host

1. Add a new host to `hosts.nix`.
2. Run `make mac-hostname <name>` to set the hostname.
3. Run `make mac-brew` to install homebrew.
4. Run `make mac-nix` to install nix.
5. Run `make mac-flake` to install the nix flake.
