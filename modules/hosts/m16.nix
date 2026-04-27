{ my, ... }:

{
  den.hosts.x86_64-darwin.m16 = {
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
  ];
}
