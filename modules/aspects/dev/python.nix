{ ... }:
{
  my.python.homeManager =
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
      home.packages = [ (pkgs.python3.withPackages pythonPackages) ];

      programs = {
        ty.enable = true;
        uv.enable = true;
      };
    };
}
