{ pkgs, ... }:

let
  monaco = pkgs.callPackage ../../pkgs/monaco { };
  monacob = pkgs.callPackage ../../pkgs/monacob { };
in

{
  home.packages = [
    monaco
    monacob
  ];
}
