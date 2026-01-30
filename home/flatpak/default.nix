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
      "com.github.Matoking.protontricks"
      "com.github.tchx84.Flatseal"
      "com.mastermindzh.tidal-hifi"
      "com.slack.Slack"
      "com.usebottles.bottles"
      "com.valvesoftware.Steam"
      "org.mozilla.Thunderbird"
      "org.videolan.VLC"
    ];

    overrides = {
      global = {
        Context.filesystems = [
          "~/.icons:ro"
          "~/.local/share/icons:ro"
          "/run/current-system/sw/share/icons:ro"
        ];
        Environment = {
          XCURSOR_THEME = "Nordzy-cursors";
          XCURSOR_SIZE = "24";
        };
      };

      "com.slack.Slack".Context.sockets = [
        "wayland"
        "!x11"
      ];
    };
  };
}
