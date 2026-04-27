{ my, ... }:
{
  den.hosts.x86_64-darwin.m16 = {
    user = "shaun";
    fontSize = 16;
    users.shaun = { };
  };

  den.aspects.m16 =
    { host, ... }:
    {
      includes = [
        my.darwin
        my.gpg
      ];

      darwin = {
        system.primaryUser = "shaun";

        nixpkgs.hostPlatform = "x86_64-darwin";
      };
    };
}
