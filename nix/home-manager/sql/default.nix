{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pgcli
    postgresql
    pspg
  ];

  xdg.configFile."pgcli/config".text = ''
    [main]
    keyword_casing = lower
    pager = pspg --style=17 --rr=2 --quit-if-one-screen --ignore-case
    vi = True
    null_string = '∅'
  '';
}
