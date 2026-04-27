{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      packages = {
        inherit (pkgs)
          bookerly
          monaco
          monacob
          sqlite-vss
          ;
      }
      // lib.optionalAttrs (lib.hasSuffix "linux" system) {
        inherit (pkgs)
          apple-display-backlight
          intercept-fn-keys
          mouser
          tws
          ;
      };
    };
}
