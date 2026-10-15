{
  lib,
  pkgs,
  whichKey,
}:
let
  # Let the menu close and restore application focus before typing. No clipboard
  # is involved, so these also work in terminals without replacing copied text.
  typeText = text: "${pkgs.wtype}/bin/wtype -s 150 -- ${lib.escapeShellArg text}";
  menuBind =
    name: letters:
    let
      menu = (pkgs.formats.yaml { }).generate "accent-${name}.yaml" {
        anchor = "center";
        menu = lib.mapAttrsToList (key: text: {
          inherit key;
          desc = text;
          cmd = typeText text;
        }) letters;
      };
    in
    {
      action.spawn = [
        whichKey
        "${menu}"
      ];
      hotkey-overlay.title = "Accent: ${name}";
      repeat = false;
    };
  cedilla = text: {
    action.spawn = [
      "${pkgs.wtype}/bin/wtype"
      "-s"
      "150"
      "--"
      text
    ];
    hotkey-overlay.title = "Type ${text}";
    repeat = false;
  };
in
{
  # Release Mod, then choose a letter (Shift+letter for uppercase); Esc cancels.
  "Mod+N" = menuBind "tilde" {
    a = "ã";
    A = "Ã";
    o = "õ";
    O = "Õ";
    n = "ñ";
    N = "Ñ";
    space = "~";
  };
  "Mod+E" = menuBind "acute" {
    a = "á";
    A = "Á";
    e = "é";
    E = "É";
    i = "í";
    I = "Í";
    o = "ó";
    O = "Ó";
    u = "ú";
    U = "Ú";
    space = "´";
  };
  "Mod+grave" = menuBind "grave" {
    a = "à";
    A = "À";
    e = "è";
    E = "È";
    i = "ì";
    I = "Ì";
    o = "ò";
    O = "Ò";
    u = "ù";
    U = "Ù";
    space = "`";
  };
  "Mod+C" = cedilla "ç";
  "Mod+Shift+C" = cedilla "Ç";
}
