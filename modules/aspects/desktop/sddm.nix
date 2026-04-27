{ ... }:

{
  my.sddm.nixos = {
    services = {
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      xserver.enable = true;
    };
  };
}
