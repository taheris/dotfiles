{ inputs, ... }:

{
  my.hex = {
    darwin.homebrew = {
      taps = [ "anomalyco/tap" ];
      casks = [ "anomalyco/tap/hex" ];
    };

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
        darwinSettings = pkgs.writeText "hex-settings.json" (
          builtins.toJSON {
            dictation_hotkey = "fn";
            shortcut_mode = "hold";
            release_microphone_while_idle = true;
            "meetings.output_folder" = "${config.home.homeDirectory}/Documents/hex";
            "meetings.enabled" = true;
            "meetings.show_recording_indicator" = true;
          }
        );
      in
      {
        imports = [ inputs.hex.homeManagerModules.default ];

        home.packages = lib.optionals isDarwin [
          (pkgs.writeShellApplication {
            name = "hex-meeting-toggle";
            runtimeInputs = [ pkgs.jq ];
            text = ''
              hex=/Applications/Hex.app/Contents/MacOS/hex
              "$hex" start
              state=$("$hex" status --json | jq -er '.meeting.state')
              case "$state" in
                idle) exec "$hex" meetings record ;;
                recording) exec "$hex" meetings stop ;;
                *) echo "Hex meeting is $state; try again when it is idle or recording." >&2; exit 1 ;;
              esac
            '';
          })
        ];

        programs.hex = {
          enable = isLinux;
          autostart = isLinux;
        };

        home.activation.hexDarwinSettings = lib.mkIf isDarwin (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            old=${lib.escapeShellArg "${config.home.homeDirectory}/Documents/Hex Meetings"}
            new=${lib.escapeShellArg "${config.home.homeDirectory}/Documents/hex"}
            if [[ -d "$old" && ! -e "$new" ]]; then
              run mv "$old" "$new"
            elif [[ -d "$old" ]]; then
              warnEcho "Both Hex meeting folders exist; move old recordings into $new manually."
            fi
            if [ -x /Applications/Hex.app/Contents/MacOS/hex ]; then
              if ! run /Applications/Hex.app/Contents/MacOS/hex settings apply ${darwinSettings}; then
                warnEcho "Hex could not apply its microphone, shortcut and meeting settings."
              fi
            else
              warnEcho "Install Hex, then rerun Home Manager to apply its settings."
            fi
          ''
        );
      };
  };
}
