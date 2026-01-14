{ pkgs, ... }:

{
  home.packages = with pkgs; [
    #mycli
    pgcli
    postgresql
    pspg
  ];

  xdg.configFile."pgcli/config".text = ''
    [main]
    keyword_casing = lower
    pager = pspg --style=17 --rr=2 --ignore-case --quit-if-one-screen --reprint-on-exit
    vi = True
    null_string = '∅'
  '';
}
