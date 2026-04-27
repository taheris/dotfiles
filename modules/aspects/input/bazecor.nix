{ ... }:
{
  my.bazecor.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bazecor ];
    };
}
