# Dotfiles configured with nix

Run `make` to see a list of setup commands.

## Layout

Built on [den](https://github.com/denful/den) with `flake-file` and
`import-tree` (dendritic pattern). Everything under `modules/` is
auto-imported; hosts compose features by including aspects from the
`my` namespace.

```
modules/
  flake/      framework wiring (inputs, defaults, formatter)
  hosts/      one file per host; hardware config inline
  users/      per-user aspects (e.g. shaun.nix)
  aspects/    reusable building blocks under `my.<name>`
    cli/      zsh starship tmux alacritty vim
    dev/      emacs python rust sql git agent
    desktop/  niri dms sddm stylix font librewolf flatpak input
    hardware/ nvidia pipewire interception linux-builder
    services/ tailscale ssh podman ollama
    secrets/  secrets gpg
    system/   linux/darwin base + shared home packages
  overlays/   local package overlay + nixpkgs fixes
packages/     custom derivation sources
```

`flake.nix` is generated from `modules/flake/inputs.nix` by
`flake-file`; do not hand-edit it.

## Bootstrapping a new NixOS host

1. Add a new host file under `modules/hosts/<name>.nix` (use
   `nix.nix` as a template — hardware config is inlined).
2. Run `make nixos-boot` to add a new boot configuration.
3. Reboot into the new system.
4. Run `make nixos-home` to install home-manager.

## Bootstrapping a new macOS host

1. Add a new host file under `modules/hosts/<name>.nix` (use
   `m1.nix`/`m16.nix` as templates).
2. Run `make mac-hostname <name>` to set the hostname.
3. Run `make mac-brew` to install homebrew.
4. Run `make mac-nix` to install nix.
5. Run `make mac-flake` to install the nix flake.
