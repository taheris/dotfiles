{ ... }:

{
  perSystem =
    { inputs', pkgs, ... }:
    let
      sandbox = inputs'.wrapix.legacyPackages.lib.mkSandbox { };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ beads ];
      };

      formatter = pkgs.nixfmt-tree;

      packages = {
        default = sandbox.package;
        sandbox = sandbox.package;
      };
    };
}
