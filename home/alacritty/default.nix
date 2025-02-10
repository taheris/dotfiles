{ host, ... }:

let
  font = "MonacoB Nerd Font Mono";

in
{
  programs.alacritty = {
    enable = true;

    settings = {
      font = {
        size = host.fontSize;
        normal.family = "${font}";
        bold.family = "${font}";
        bold_italic.family = "${font}";
        italic.family = "${font}";
      };

      colors = {
        primary.background = "#282a36";
        primary.foreground = "#f8f8f2";

        cursor.cursor = "#f8f8f2";
        cursor.text = "#44475a";

        normal.black = "#282a36";
        normal.blue = "#6272a4";
        normal.cyan = "#8be9fd";
        normal.green = "#50fa7b";
        normal.magenta = "#ff79c6";
        normal.red = "#ff5555";
        normal.white = "#f8f8f2";
        normal.yellow = "#f1fa8c";

        bright.black = "#44475a";
        bright.blue = "#828fb7";
        bright.cyan = "#bdf3fe";
        bright.green = "#82fba0";
        bright.magenta = "#ffacdc";
        bright.red = "#ff8888";
        bright.white = "#ffffff";
        bright.yellow = "#f7fcbd";

        dim.black = "#14151b";
        dim.blue = "#4d5b86";
        dim.cyan = "#59dffc";
        dim.green = "#1ef956";
        dim.magenta = "#ff46b0";
        dim.red = "#ff2222";
        dim.white = "#e6e6d1";
        dim.yellow = "#ebf85b";
      };

      env.TERM = "xterm-256color";
      scrolling.history = 100000;
      selection.save_to_clipboard = true;
      window.option_as_alt = "Both";
    };
  };
}
