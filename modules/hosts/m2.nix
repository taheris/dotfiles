{ my, ... }:

{
  den.hosts.m2 = {
    system = "aarch64-darwin";
    user = "shaun";
    fontSize = 16;
    builders = {
      wrix.enable = true;
      nix.enable = false;
    };
    users.shaun = { };
  };

  den.aspects.m2.includes = [
    my.bettertouchtool
    my.darwin
    my.font
    my.gpg
    my.karabiner
    my.leader-key
    my.obs-video-crop
    my.omniwm
    my.hex
    my.stylix
    my.vlc
  ];
}
