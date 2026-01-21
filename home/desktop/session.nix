{ pkgs, spawnTerminal }:

let
  jq = "${pkgs.jq}/bin/jq";
  sessionFile = "$XDG_DATA_HOME/niri-session/session.json";

  # Map app_id to spawn command - apps with internal session restore should only spawn once
  spawnCommands = {
    Alacritty = "${spawnTerminal}";
    emacs = "emacsclient -c -a emacs";
  };

  # Apps that manage their own session restore (only spawn one instance)
  singleInstanceApps = [ "librewolf" "firefox" "chromium" "chrome" ];
in
{
  save = pkgs.writeShellScript "niri-session-save" ''
    set -euo pipefail

    mkdir -p "$(dirname "${sessionFile}")"

    windows=$(niri msg -j windows)
    workspaces=$(niri msg -j workspaces)

    echo "$windows" | ${jq} --argjson ws "$workspaces" '
      ($ws | map({(.id | tostring): .idx}) | add) as $ws_idx |
      map({
        app_id,
        title,
        workspace_idx: $ws_idx[.workspace_id | tostring],
        is_focused
      }) |
      sort_by(.workspace_idx)
    ' > "${sessionFile}.tmp"

    mv "${sessionFile}.tmp" "${sessionFile}"
  '';

  restore = pkgs.writeShellScript "niri-session-restore" ''
    set -euo pipefail

    if [ ! -f "${sessionFile}" ]; then
      echo "No session file found"
      exit 0
    fi

    session=$(cat "${sessionFile}")
    if [ -z "$session" ] || [ "$session" = "[]" ]; then
      echo "Session file is empty"
      exit 0
    fi

    echo "Restoring session..."

    # App-specific spawn commands
    get_spawn_cmd() {
      case "$1" in
        Alacritty) echo "${spawnCommands.Alacritty}" ;;
        emacs) echo "${spawnCommands.emacs}" ;;
        *) echo "$1" ;;
      esac
    }

    # Apps that handle their own session restore (only spawn one)
    is_single_instance() {
      case "$1" in
        ${builtins.concatStringsSep "|" singleInstanceApps}) return 0 ;;
        *) return 1 ;;
      esac
    }

    # Spawn windows for each app, accounting for already-running instances
    for app in $(echo "$session" | ${jq} -r '[.[].app_id] | unique | .[]'); do
      needed=$(echo "$session" | ${jq} --arg app "$app" '[.[] | select(.app_id == $app)] | length')
      existing=$(niri msg -j windows | ${jq} --arg app "$app" '[.[] | select(.app_id == $app)] | length')

      # Single-instance apps only need one spawn (they restore their own windows)
      if is_single_instance "$app"; then
        if [ "$existing" -eq 0 ]; then
          echo "Spawning single instance of: $app (has internal session restore)"
          spawn_cmd=$(get_spawn_cmd "$app")
          niri msg action spawn -- $spawn_cmd &
          sleep 1
        fi
        continue
      fi

      to_spawn=$((needed - existing))
      if [ "$to_spawn" -gt 0 ]; then
        echo "Spawning $to_spawn instance(s) of: $app"
        spawn_cmd=$(get_spawn_cmd "$app")
        for _ in $(seq 1 "$to_spawn"); do
          niri msg action spawn -- $spawn_cmd &
          sleep 1
        done
      fi
    done

    # Wait for windows to appear
    echo "Waiting for windows..."
    expected=$(echo "$session" | ${jq} 'length')
    for _ in {1..30}; do
      current=$(niri msg -j windows | ${jq} 'length')
      [ "$current" -ge "$expected" ] && break
      sleep 1
    done

    # Final wait for windows to settle
    sleep 2

    # Get current windows and determine max existing workspace
    current_windows=$(niri msg -j windows)
    max_ws=$(niri msg -j workspaces | ${jq} 'map(.idx) | max // 1')

    # Process saved windows (sorted by workspace_idx)
    while IFS= read -r saved; do
      title=$(echo "$saved" | ${jq} -r '.title')
      app=$(echo "$saved" | ${jq} -r '.app_id')
      ws=$(echo "$saved" | ${jq} -r '.workspace_idx')

      # Match by exact title first, then by app_id
      window_id=$(echo "$current_windows" | ${jq} -r --arg t "$title" --arg a "$app" '
        (.[] | select(.title == $t) | .id) //
        (.[] | select(.app_id == $a) | .id) //
        empty
      ' | head -1)

      if [ -n "$window_id" ] && [ "$ws" != "null" ]; then
        echo "Moving window $window_id ($title) to workspace $ws"

        if [ "$ws" -gt "$max_ws" ]; then
          # Target workspace doesn't exist - move window to last workspace,
          # then use move-column-to-workspace-down to create new workspaces
          niri msg action focus-window --id "$window_id"
          niri msg action move-window-to-workspace "$max_ws"
          while [ "$max_ws" -lt "$ws" ]; do
            niri msg action move-column-to-workspace-down
            max_ws=$((max_ws + 1))
          done
        else
          # Target workspace exists, move directly
          niri msg action move-window-to-workspace --window-id "$window_id" "$ws"
        fi

        # Remove matched window from pool
        current_windows=$(echo "$current_windows" | ${jq} --argjson id "$window_id" 'map(select(.id != $id))')
      else
        echo "Could not find window for: $title ($app)"
      fi
    done < <(echo "$session" | ${jq} -c '.[]')

    # Restore focus
    focused_ws=$(echo "$session" | ${jq} -r '.[] | select(.is_focused) | .workspace_idx // empty')
    [ -n "$focused_ws" ] && niri msg action focus-workspace "$focused_ws"

    echo "Session restore complete"
  '';
}
