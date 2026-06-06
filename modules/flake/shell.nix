{ ... }:

{
  perSystem =
    { inputs', pkgs, ... }:
    let
      wrix = inputs'.wrix.legacyPackages.lib;

      agent = "pi";
      packages = [ pkgs.gnumake ];

      sandbox = wrix.mkSandbox {
        inherit agent packages;
      };

      debugSandbox = wrix.mkSandbox {
        inherit agent;
        packages = packages ++ [ pkgs.podman ];
      };

    in
    {
      devShells.default = wrix.mkDevShell {
        inherit packages;
        profile = wrix.profiles.base;
      };

      formatter = pkgs.nixfmt-tree;

      packages = {
        default = sandbox.package;
        sandbox = sandbox.package;
        debug = debugSandbox.package;
      };
    };
}
