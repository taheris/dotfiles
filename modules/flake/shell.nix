{ ... }:

{
  perSystem =
    { inputs', pkgs, ... }:
    let
      wrix = inputs'.wrix.legacyPackages.lib;

      sandbox = wrix.mkSandbox {
        profile = wrix.profiles.base;
        agent = "pi";
      };

      debugSandbox = wrix.mkSandbox {
        profile = wrix.profiles.base;
        agent = "pi";
        packages = [ pkgs.podman ];
      };
    in
    {
      devShells.default = sandbox.devShell { };

      formatter = pkgs.nixfmt-tree;

      packages = {
        default = sandbox.package;
        sandbox = sandbox.package;
        debug = debugSandbox.package;
      };
    };
}
