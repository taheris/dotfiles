{ pkgs, ... }:

let
  pythonPackages =
    pythonPkgs: with pythonPkgs; [
      fastapi
      jupyter
      kaleido
      numpy
      pandas
      plotly
      pydantic
      pytest
      requests
      ruff
      scikit-learn
    ];

in
{
  home.packages = with pkgs; [
    (python3.withPackages pythonPackages)
    ty
    uv
  ];
}
