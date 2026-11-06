{ my, ... }:

{
  den.hosts.m1 = {
    system = "aarch64-darwin";
    user = "shaun";
    fontSize = 16;
    builders = {
      wrix.enable = true;
      nix.enable = false;
    };
    users.shaun = { };
  };

  den.aspects.m1.includes = [
    my.bettertouchtool
    my.darwin
    my.font
    my.gpg
    my.karabiner
    my.leader-key
    my.omniwm
    my.hex
    my.stylix
    my.vlc
  ];
}
