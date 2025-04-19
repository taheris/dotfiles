{ pkgs, ... }:

let
  pythonPackages =
    pythonPkgs: with pythonPkgs; [
      jupyter
      numpy
      pandas
      plotly
      requests
      ruff
      scikit-learn
    ];

in
{
  home.packages = with pkgs; [
    (python3.withPackages pythonPackages)
    uv
  ];
}
