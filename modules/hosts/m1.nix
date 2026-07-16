{ my, ... }:

{
  den.hosts.m1 = {
    system = "aarch64-darwin";
    user = "shaun";
    fontSize = 16;
    hasLinuxBuilder = true;
    users.shaun = { };
  };

  den.aspects.m1.includes = [
    my.darwin
    my.font
    my.gpg
    my.karabiner
    my.sox
    my.stylix
  ];
}
