{
  lib,
  host,
  pkgs,
  ...
}:

let
  inherit (lib) hasSuffix mkIf;
  isLinux = hasSuffix "linux" host.system;

in
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
    polarity = "dark";

    cursor = mkIf isLinux {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
      size = 24;
    };

    image = mkIf isLinux (pkgs.fetchurl {
      url = "https://images.unsplash.com/photo-1729614499383-756f6e0e4d80";
      sha256 = "05c2rx7i7k7w87dnzjcn1znbvj00q21a956kmqs4mfw558rxnmfw";
      name = "wallpaper.jpg";
    });

    fonts = {
      monospace = {
        name = "MonacoB Nerd Font Mono";
        package = pkgs.monacob;
      };
      serif = {
        name = "Bookerly";
        package = pkgs.bookerly;
      };
      sansSerif = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
      };
      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-color-emoji;
      };
    };

    targets = {
      emacs.enable = false;
      librewolf.profileNames = mkIf isLinux [ "default" ];
      wpaperd.enable = mkIf isLinux true;
    };
  };
}
