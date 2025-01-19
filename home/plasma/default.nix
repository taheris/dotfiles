{ lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;

in
{
  programs.plasma = mkIf isLinux {
    enable = true;

    configFile.kwinrc.Desktops = {
      Id_1 = "41599782-7a07-4f40-987e-5330afb88f5b";
      Id_2 = "9339ef3d-db5f-4358-b64e-2053fd42b04f";
      Id_3 = "8bdf15fb-05f7-4976-9898-002f2a9e2ff3";
      Id_4 = "bea6b9e4-4050-432b-92ab-123da55fe97b";
      Id_5 = "1f349648-1990-4d84-9fc3-004e2ab6492a";
      Number = 5;
      Rows = 1;
    };

    panels = [
      {
        hiding = "autohide";
        location = "bottom";

        widgets = [
          {
            kickoff = {
              sortAlphabetically = true;
              icon = "nix-snowflake-white";
            };
          }

          {
            iconTasks = {
              launchers = [
                "applications:org.kde.dolphin.desktop"
              ];
            };
          }

          "org.kde.plasma.marginsseparator"

          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.bluetooth"
              ];
              hidden = [
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.volume"
              ];
            };
          }

          {
            digitalClock = {
              calendar.firstDayOfWeek = "monday";
              time.format = "24h";
            };
          }
        ];
      }
    ];

    shortcuts.kwin = {
      "Switch One Desktop to the Left" = "Meta+Alt+H";
      "Switch One Desktop Down" = "Meta+Alt+J";
      "Switch One Desktop Up" = "Meta+Alt+K";
      "Switch One Desktop to the Right" = "Meta+Alt+L";

      "Window One Desktop to the Left" = "Meta+Shift+H";
      "Window One Desktop Down" = "Meta+Shift+J";
      "Window One Desktop Up" = "Meta+Shift+K";
      "Window One Desktop to the Right" = "Meta+Shift+L";

      "Window Quick Tile Left" = "Meta+Alt+Shift+H";
      "Window Quick Tile Bottom" = "Meta+Alt+Shift+J";
      "Window Quick Tile Top" = "Meta+Alt+Shift+K";
      "Window Quick Tile Right" = "Meta+Alt+Shift+L";

      "Switch to Desktop 1" = "Meta+Alt+1";
      "Switch to Desktop 2" = "Meta+Alt+2";
      "Switch to Desktop 3" = "Meta+Alt+3";
      "Switch to Desktop 4" = "Meta+Alt+4";
      "Switch to Desktop 5" = "Meta+Alt+5";
      "Switch to Desktop 6" = "Meta+Alt+6";
      "Switch to Desktop 7" = "Meta+Alt+7";
      "Switch to Desktop 8" = "Meta+Alt+8";
      "Switch to Desktop 9" = "Meta+Alt+9";

      "Window to Desktop 1" = "Meta+Shift+1";
      "Window to Desktop 2" = "Meta+Shift+2";
      "Window to Desktop 3" = "Meta+Shift+3";
      "Window to Desktop 4" = "Meta+Shift+4";
      "Window to Desktop 5" = "Meta+Shift+5";
      "Window to Desktop 6" = "Meta+Shift+6";
      "Window to Desktop 7" = "Meta+Shift+7";
      "Window to Desktop 8" = "Meta+Shift+8";
      "Window to Desktop 9" = "Meta+Shift+9";

      "Window Raise" = "Meta+Alt+>";
      "Window Lower" = "Meta+Alt+<";
      "Show Desktop" = "Meta+Alt+D";
      "Expose" = "Meta+Alt+E";
      "Grid View" = "Meta+Alt+G";
      "Activate Window Demanding Attention" = "Meta+Alt+A";

      "Window Close" = "Meta+Alt+Shift+Q";
      "Window Maximize" = "Meta+Alt+Shift+M";
      "Window No Border" = "Meta+Alt+Shift+B";
      "Window Fullscreen" = "Meta+Alt+Shift+F";
      "Window Move Center" = "Meta+Alt+Shift+C";
      "Window Grow Horizontal" = "Meta+Alt+Shift+>";
      "Window Shrink Horizontal" = "Meta+Alt+Shift+<";
    };
  };
}
