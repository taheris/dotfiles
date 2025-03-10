{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOptionDefault;
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

      {
        appId = "com.onepassword.OnePassword//stable";
        origin = "onepassword-origin";
      }
    ];

    remotes = mkOptionDefault [
      {
        name = "onepassword-origin";
        location = "https://downloads.1password.com/linux/flatpak/repo/";
        gpg-import = "src/github.com/taheris/dotfiles/home/flatpak/1password.asc";
      }
    ];

    overrides = {
      "com.slack.Slack".Context.sockets = [
        "wayland"
        "!x11"
      ];
    };
  };
}
