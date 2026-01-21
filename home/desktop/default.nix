{
  inputs,
  lib,
  host,
  pkgs,
  ...
}:

let
  session = import ./session.nix { inherit pkgs; };

  inherit (lib)
    hasSuffix
    listToAttrs
    optionalAttrs
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

  # Spawn terminal in last directory
  spawnTerminal = pkgs.writeShellScript "spawn-terminal" ''
    dir="$XDG_RUNTIME_DIR/last-dir"
    if [ -f "$dir" ]; then
      exec alacritty --working-directory "$(cat "$dir")" -e tmux
    else
      exec alacritty -e tmux
    fi
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
  home = {
    packages = with pkgs; [
      catppuccin-gtk
      playerctl
      tela-icon-theme
      wpaperd
      xwayland-satellite
      (writeShellScriptBin "niri-session-save" "exec ${session.save}")
      (writeShellScriptBin "niri-session-restore" "exec ${session.restore}")
    ];
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
          "Mod+H".action.focus-column-left = [ ];
          "Mod+Shift+H".action.focus-column-first = [ ];
          "Mod+J".action.spawn = [ "${focusDownWrap}" ];
          "Mod+Shift+J".action.spawn = [ "${newWorkspaceBelow}" ];
          "Mod+K".action.spawn = [ "${focusUpWrap}" ];
          "Mod+Shift+K".action.spawn = [ "${newWorkspaceAbove}" ];
          "Mod+L".action.focus-column-right = [ ];
          "Mod+Shift+L".action.focus-column-last = [ ];

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
          "Mod+V".action.center-column = [ ];
          "Mod+Alt+V".action.center-visible-columns = [ ];
          "Mod+Minus".action.set-column-width = "-5%";
          "Mod+Equal".action.set-column-width = "+5%";

          # Spawn apps
          "Mod+E" = spawn "emacsclient -c -a emacs";
          "Mod+T".action.spawn = [ "${spawnTerminal}" ];
          "Mod+W" = spawn "librewolf";

          # DMS
          "Mod+Space" = dms "spotlight toggle";
          "Mod+Comma" = dms "settings toggle";
          "Mod+Period" = dms "notepad toggle";
          "Mod+M" = dms "processlist toggle";
          "Mod+N" = dms "notifications toggle";
          "Mod+P" = dms "clipboard toggle";
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
        // workspaceBinds "Mod+" "focus-workspace"
        // workspaceBinds "Mod+Alt+" "move-column-to-workspace";

        gestures.hot-corners.enable = false;

        cursor = {
          theme = "Nordzy-cursors";
          size = 24;
        };

        input.keyboard = {
          repeat-delay = 200;
          repeat-rate = 30;
        };

        layout = {
          center-focused-column = "on-overflow";
          default-column-width.proportion = 0.5;

          shadow = {
            enable = true;
            softness = 20;
            spread = 5;
            offset = {
              x = 0;
              y = 0;
            };
            color = "rgba(235 73 55 1.0)";
            inactive-color = "rgba(0 0 0 0.0)";
          };
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
          { command = [ "${session.restore}" ]; }
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
    wpaperd.enable = true;
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

  systemd.user = {
    services.niri-session-save = {
      Unit = {
        Description = "Save niri session state";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${session.save}";
      };
    };

    timers.niri-session-save = {
      Unit = {
        Description = "Periodically save niri session state";
        After = [ "graphical-session.target" ];
      };
      Timer = {
        OnBootSec = "5min";
        OnUnitActiveSec = "5min";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
