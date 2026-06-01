{ ... }:

{
  perSystem =
    { inputs', pkgs, ... }:
    let
      wrapix = inputs'.wrapix.legacyPackages.lib;

      sandbox = wrapix.mkSandbox { };
      debugSandbox = wrapix.mkSandbox {
        packages = [ pkgs.podman ];
      };

    in
    {
      devShells.default = wrapix.mkDevShell {
        profile = wrapix.profiles.base;
      };

      formatter = pkgs.nixfmt-tree;

      packages = {
        default = sandbox.package;
        sandbox = sandbox.package;
        debug = debugSandbox.package;
      };
    };
}
