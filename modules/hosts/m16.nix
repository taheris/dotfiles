{ my, ... }:

{
  den.hosts.m16 = {
    system = "x86_64-darwin";
    user = "shaun";
    fontSize = 16;
    users.shaun = { };
  };

  den.aspects.m16.includes = [
    my.darwin
    my.font
    my.gpg
    my.karabiner
    my.sox
    my.stylix
  ];
}
