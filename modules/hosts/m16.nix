{ my, ... }:
{
  den.hosts.x86_64-darwin.m16 = {
    user = "shaun";
    fontSize = 16;
    users.shaun = { };
  };

  den.aspects.m16 =
    { ... }:
    {
      includes = [
        my.darwin
        my.gpg
      ];

      darwin = {
        nixpkgs.hostPlatform = "x86_64-darwin";
        system.primaryUser = "shaun";
      };
    };
}
