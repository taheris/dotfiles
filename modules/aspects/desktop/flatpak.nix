{ inputs, ... }:
{
  my.flatpak = {
    homeManager = {
      imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

      services.flatpak = {
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

          "com.mastermindzh.tidal-hifi" = {
            # chromium triggered amdgpu page faults that took down niri
            Environment.ELECTRON_DISABLE_GPU = "1";

            # allow mpris export to host session bus for dms media widget
            "Session Bus Policy"."org.mpris.MediaPlayer2.*" = "own";
          };

          "com.slack.Slack".Context.sockets = [
            "wayland"
            "!x11"
          ];
        };
      };
    };

    nixos = {
      services.flatpak.enable = true;
    };
  };
}
