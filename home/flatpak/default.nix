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
      "com.github.tchx84.Flatseal".Environment = {
        # https://github.com/tchx84/Flatseal/issues/726
        GSK_RENDERER = "ngl";
      };

      "com.slack.Slack".Context.sockets = [ "wayland" ];
      "com.usebottles.bottles".Context.sockets = [ "!wayland" ];
    };
  };
}
