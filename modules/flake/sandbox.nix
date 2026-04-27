{ ... }:
{
  perSystem =
    { inputs', ... }:
    let
      sandbox = inputs'.wrapix.legacyPackages.lib.mkSandbox { };
    in
    {
      packages.default = sandbox.package;
      packages.sandbox = sandbox.package;
    };
}
