{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;

in
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = mkIf isLinux {
    enable = true;
    uninstallUnmanaged = true;
    update.onActivation = true;

    packages = [
      "com.bitwarden.desktop"
      "com.discordapp.Discord"
      "com.github.tchx84.Flatseal"
      "com.mastermindzh.tidal-hifi"
      "com.slack.Slack"
      "com.usebottles.bottles"
      "com.valvesoftware.Steam"
      "org.mozilla.Thunderbird"
    ];

    overrides = {
      "com.slack.Slack".Context.sockets = [
        "wayland"
        "!x11"
      ];
    };
  };
}
