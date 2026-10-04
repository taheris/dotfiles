{ lib, ... }:

let
  inherit (builtins) fromJSON;
  inherit (lib)
    mkForce
    optionals
    stringToCharacters
    toUpper
    ;

  escape = fromJSON ''"\u001b"'';

  metaBinding = mods: key: text: {
    inherit key mods;
    chars = "${escape}${text}";
    mode = "~Vi|~Search";
  };

  # Send the Meta sequences used by tmux.nix's root and passthrough tables.
  # Karabiner routes Command-Space to tmux only while Alacritty is focused.
  # Keep Command-Grave for macOS window cycling; Option-Grave retains its tmux action.
  commandBindings =
    # Keep Command-V for paste; Option-V still splits panes.
    map (key: metaBinding "Command" (toUpper key) key) (
      stringToCharacters "bcdfhjklnopqrswxz123456789=,./"
    )
    ++ map (key: metaBinding "Command|Shift" key key) (stringToCharacters "HJKLQR?")
    ++ [
      (metaBinding "Command" "Enter" "\r")
      # Karabiner routes Command-H only while Alacritty is focused.
      # Remove this and the Karabiner Command-H rule when native Hide is overridable.
      # https://github.com/alacritty/alacritty/issues/7689
      (metaBinding "None" "F17" "h") # Command+H
      (metaBinding "None" "F20" " ") # Command+Space
    ];

in
{
  my.alacritty.homeManager =
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;

    in
    {
      programs.alacritty = {
        enable = true;

        settings = {
          font.size = mkForce config.my.fontSize;
          scrolling.history = 100000;
          selection.save_to_clipboard = true;
          window.option_as_alt = "Both";

          env = {
            TERM = "xterm-256color";
          };

          keyboard.bindings = [
            {
              key = "Return";
              mods = "Shift";
              chars = "${escape}[13;2u";
            }
          ]
          ++ optionals isDarwin commandBindings;
        };
      };
    };
}
