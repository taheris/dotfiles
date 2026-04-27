# Dotfiles configured with nix

Run `make` to see a list of setup commands.

## Layout

Built on [den](https://github.com/denful/den) (dendritic pattern).

Everything under `modules/` is auto-imported. Hosts compose features by
including aspects from the `my` namespace.

```
modules/
  flake/      framework wiring (inputs, defaults, formatter)
  hosts/      one file per host; hardware config inline
  users/      per-user aspects (e.g. shaun.nix)
  aspects/    reusable building blocks under `my.<name>`
    cli/      zsh starship tmux alacritty vim dotfile
    dev/      emacs python rust sql git agent
    desktop/  niri dms sddm stylix font librewolf flatpak
    hardware/ nvidia pipewire interception
    input/    karabiner mouser bazecor sox yubikey
    services/ tailscale ssh podman ollama
    secrets/  secrets gpg
    system/   linux/darwin base + shared home packages
  overlays/   local package overlay + nixpkgs fixes
packages/     custom derivation sources
```

`flake.nix` is generated from `modules/flake/inputs.nix` by `flake-file`.
After editing inputs, run `nix run .#write-flake` to regenerate.

## Adding an aspect

1. Drop a file under the matching `modules/aspects/<group>/<name>.nix`.
2. Define `my.<name>.{nixos,darwin,homeManager} = { ... };` (any subset).
3. For host-conditional behavior, wrap with `{ host, ... }:` and read
   `host.system`, `host.user`, or any custom `den.schema.host.*` option.
4. Include from a host (`den.aspects.<host>.includes`) or from a user
   (`den.aspects.<user>.includes`). Host-side `homeManager` blocks flow
   to bound users automatically via `den.provides.host-aspects`.

## Bootstrapping

### A new NixOS host

1. Add a new host file under `modules/hosts/<name>.nix`.
2. Run `make nixos-boot` to add a new boot configuration.
3. Reboot into the new system.
4. Run `make nixos-home` to install home-manager.

### A new macOS host

1. Add a new host file under `modules/hosts/<name>.nix`.
2. Run `make mac-hostname <name>` to set the hostname.
3. Run `make mac-brew` to install homebrew.
4. Run `make mac-nix` to install nix.
5. Run `make mac-flake` to install the nix flake.
