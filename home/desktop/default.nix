{
  inputs,
  lib,
  host,
  pkgs,
  ...
}:

let
  inherit (lib)
    hasSuffix
    listToAttrs
    optionalAttrs
    optionalString
    range
    splitString
    ;

  spawn = cmd: { action.spawn = splitString " " cmd; };
  dms = cmd: spawn "dms ipc ${cmd}";

  # Focus up a column if it exists, or up a workspace otherwise (wrapping)
  focusUpWrap = pkgs.writeShellScript "focus-up-wrap" ''
    before=$(niri msg -j focused-window | ${pkgs.jq}/bin/jq '.id')
    niri msg action focus-window-up
    after=$(niri msg -j focused-window | ${pkgs.jq}/bin/jq '.id')
    if [ "$before" != "$after" ]; then
      exit 0
    fi

    current=$(niri msg -j workspaces | ${pkgs.jq}/bin/jq '.[] | select(.is_focused) | .idx')
    if [ "$current" = "1" ]; then
      count=$(niri msg -j workspaces | ${pkgs.jq}/bin/jq 'length')
      niri msg action focus-workspace "$count"
      niri msg action focus-workspace-up
    else
      niri msg action focus-workspace-up
    fi
  '';

  # Focus down a column if it exists, or down a workspace otherwise (wrapping)
  focusDownWrap = pkgs.writeShellScript "focus-down-wrap" ''
    before=$(niri msg -j focused-window | ${pkgs.jq}/bin/jq '.id')
    niri msg action focus-window-down
    after=$(niri msg -j focused-window | ${pkgs.jq}/bin/jq '.id')
    if [ "$before" != "$after" ]; then
      exit 0
    fi

    current=$(niri msg -j workspaces | ${pkgs.jq}/bin/jq '.[] | select(.is_focused) | .idx')
    count=$(niri msg -j workspaces | ${pkgs.jq}/bin/jq 'length')
    if [ "$current" = "$((count - 1))" ]; then
      niri msg action focus-workspace 1
    else
      niri msg action focus-workspace-down
    fi
  '';

  # Create a new workspace above the current one
  newWorkspaceAbove = pkgs.writeShellScript "new-workspace-above" ''
    current=$(niri msg -j workspaces | ${pkgs.jq}/bin/jq '.[] | select(.is_focused) | .idx')
    count=$(niri msg -j workspaces | ${pkgs.jq}/bin/jq 'length')
    niri msg action focus-workspace "$count"
    niri msg action focus-workspace-down
    niri msg action move-workspace-to-index "$current"
  '';

  # Create a new workspace below the current one
  newWorkspaceBelow = pkgs.writeShellScript "new-workspace-below" ''
    current=$(niri msg -j workspaces | ${pkgs.jq}/bin/jq '.[] | select(.is_focused) | .idx')
    count=$(niri msg -j workspaces | ${pkgs.jq}/bin/jq 'length')
    niri msg action focus-workspace "$count"
    niri msg action focus-workspace-down
    niri msg action move-workspace-to-index "$((current + 1))"
  '';

  workspaceBinds =
    prefix: action:
    listToAttrs (
      map (n: {
        name = "${prefix}${toString n}";
        value.action.${action} = n;
      }) (range 1 9)
    );

in
optionalAttrs (hasSuffix "linux" host.system) {
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-name = "Noto Sans";
    };
  };

  home = {
    packages = with pkgs; [
      catppuccin-gtk
      playerctl
      tela-icon-theme
      xwayland-satellite
    ];

    pointerCursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;

      gtk.enable = true;
      x11.enable = true;
    };

    sessionVariables = {
      GTK_THEME = "catppuccin-mocha-blue-standard+default";
      QS_ICON_THEME = "Tela";
    };

  };

  programs = {
    dank-material-shell = {
      enable = true;
      managePluginSettings = true;

      niri = {
        enableSpawn = false;
        enableKeybinds = false;
      };

      plugins = {
        dockerManager.enable = true;

        mediaPlayer = {
          enable = true;
          settings.preferredSource = "tidal";
        };
      };
    };

    niri = {
      enable = true;
      package = inputs.niri.packages.${host.system}.niri-unstable;

      settings = {
        binds = {
          # Window focus
          "Mod+H".action.focus-column-left-or-last = [ ];
          "Mod+J".action.spawn = [ "${focusDownWrap}" ];
          "Mod+Shift+J".action.spawn = [ "${newWorkspaceBelow}" ];
          "Mod+K".action.spawn = [ "${focusUpWrap}" ];
          "Mod+Shift+K".action.spawn = [ "${newWorkspaceAbove}" ];
          "Mod+L".action.focus-column-right-or-first = [ ];

          # Window move
          "Mod+Alt+H".action.move-column-left = [ ];
          "Mod+Alt+Shift+H".action.swap-window-left = [ ];
          "Mod+Alt+J".action.move-window-down-or-to-workspace-down = [ ];
          "Mod+Alt+Shift+J".action.move-column-to-workspace-down = [ ];
          "Mod+Alt+K".action.move-window-up-or-to-workspace-up = [ ];
          "Mod+Alt+Shift+K".action.move-column-to-workspace-up = [ ];
          "Mod+Alt+L".action.move-column-right = [ ];
          "Mod+Alt+Shift+L".action.swap-window-right = [ ];

          # Window action
          "Mod+O".action.toggle-overview = [ ];
          "Mod+S".action.toggle-window-floating = [ ];
          "Mod+C".action.consume-window-into-column = [ ];
          "Mod+X".action.expel-window-from-column = [ ];
          "Mod+Q" = {
            action.close-window = [ ];
            repeat = false;
          };

          # Window size
          "Mod+F".action.maximize-column = [ ];
          "Mod+Alt+F".action.fullscreen-window = [ ];
          "Mod+R".action.switch-preset-column-width = [ ];
          "Mod+Shift+R".action.switch-preset-column-width-back = [ ];
          "Mod+Minus".action.set-column-width = "-5%";
          "Mod+Equal".action.set-column-width = "+5%";

          # Spawn apps
          "Mod+E" = spawn "emacsclient -c -a emacs";
          "Mod+T" = spawn "alacritty -e tmux";
          "Mod+W" = spawn "librewolf";

          # DMS
          "Mod+Space" = dms "spotlight toggle";
          "Mod+Comma" = dms "settings toggle";
          "Mod+M" = dms "processlist toggle";
          "Mod+N" = dms "notifications toggle";
          "Mod+P" = dms "notepad toggle";
          "Mod+V" = dms "clipboard toggle";
          "Mod+Alt+Shift+P" = dms "powermenu toggle";
          "Mod+Alt+Shift+N" = dms "night toggle";

          # Media keys
          "XF86AudioRaiseVolume" = dms "audio increment 3";
          "XF86AudioLowerVolume" = dms "audio decrement 3";
          "XF86AudioNext" = spawn "playerctl next";
          "XF86AudioPrev" = spawn "playerctl previous";
          "XF86AudioPlay" = spawn "playerctl play-pause";
          "XF86AudioMute" = dms "audio mute";
          "XF86AudioMicMute" = dms "audio micmute";
          "XF86MonBrightnessUp" = dms "brightness increment 5";
          "XF86MonBrightnessDown" = dms "brightness decrement 5";

          # Session
          "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];

          # Screenshots
          "Mod+F3".action.screenshot = [ ];
          "Mod+F4".action.screenshot-screen = [ ];
          "Mod+F5".action.screenshot-window = [ ];
        }
        // workspaceBinds "Mod+Alt+" "focus-workspace"
        // workspaceBinds "Mod+Shift+" "move-column-to-workspace";

        gestures.hot-corners.enable = false;

        input.keyboard = {
          repeat-delay = 200;
          repeat-rate = 30;
        };

        layout = {
          center-focused-column = "always";
          default-column-width.proportion = 0.5;
        };

        hotkey-overlay.skip-at-startup = true;
        prefer-no-csd = true;

        spawn-at-startup = [
          {
            command = [
              "dms"
              "run"
            ];
          }
        ];

        window-rules = [
          {
            matches = [
              { app-id = "^Alacritty$"; }
              { app-id = "^emacs$"; }
            ];
            default-column-width.proportion = 0.4;
          }

          {
            matches = [
              { app-id = "^steam"; }
            ];
            open-floating = true;
          }
        ];
      };
    };
  };

  services = {
    mako.enable = true;
    polkit-gnome.enable = true;
  };

  xdg = {
    enable = true;
    mimeApps.enable = true;

    portal = {
      enable = true;
      config.common.default = "gtk";
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
