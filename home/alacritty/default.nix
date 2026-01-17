{ lib, host, ... }:

{
  programs.alacritty = {
    enable = true;

    settings = {
      font.size = lib.mkForce host.fontSize;
      env.TERM = "xterm-256color";
      scrolling.history = 100000;
      selection.save_to_clipboard = true;
      window.option_as_alt = "Both";

      keyboard.bindings = [
        {
          key = "Return";
          mods = "Shift";
          chars = "\\u001b\\u000a";
        }
      ];
    };
  };
}
