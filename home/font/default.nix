{ pkgs, ... }:

{
  home.packages = with pkgs; [
    monaco
    monacob
  ];
}
