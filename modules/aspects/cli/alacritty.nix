{ lib, ... }:

let
  inherit (builtins) fromJSON;
  inherit (lib) mkForce;

in
{
  my.alacritty =
    { host, ... }:
    {
      homeManager = {
        programs.alacritty = {
          enable = true;

          settings = {
            font.size = mkForce host.fontSize;
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
                chars = fromJSON ''"\u001b\u000a"'';
              }
            ];
          };
        };
      };
    };
}
