{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bookerly
    font-awesome
    ibm-plex
    julia-mono
    libre-baskerville
    monaco
    monacob
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    roboto
  ];

  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      monospace = [ "MonacoB Nerd Font Mono" ];
      serif = [ "Bookerly" ];
      sansSerif = [ "Noto Sans" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
