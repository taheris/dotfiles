{ ... }:

{
  perSystem =
    { inputs', pkgs, ... }:
    let
      wrix = inputs'.wrix.legacyPackages.lib;

      agent = "pi";
      packages = with pkgs; [
        gnumake
        openssh
      ];
      profile = wrix.profiles.base;

      sandbox = wrix.mkSandbox {
        inherit agent packages;
      };

      debugSandbox = wrix.mkSandbox {
        inherit agent;
        packages = packages ++ [ pkgs.podman ];
      };

    in
    {
      devShells.default =
        if pkgs.stdenv.isDarwin then
          pkgs.mkShell {
            packages = (profile.hostPackages or profile.packages) ++ packages;
            env = profile.env or { };
            shellHook = ''
              echo "Wrix development shell"
              ${profile.shellHook or ""}
            '';
          }
        else
          wrix.mkDevShell {
            inherit packages profile;
          };

      formatter = pkgs.nixfmt-tree;

      packages = {
        default = sandbox.package;
        sandbox = sandbox.package;
        debug = debugSandbox.package;
      };
    };
}
