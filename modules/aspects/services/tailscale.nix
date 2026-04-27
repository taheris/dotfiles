{ ... }:

{
  my.tailscale.nixos =
    { lib, ... }:
    {
      services.tailscale.enable = true;

      networking.firewall.interfaces.tailscale0 = {
        allowedTCPPorts = [ 22 ];
        allowedUDPPortRanges = [
          {
            from = 60000;
            to = 61000;
          }
        ];
      };

      systemd.services.tailscaled.serviceConfig.Environment = lib.mkAfter [
        "TS_NO_LOGS_NO_SUPPORT=true"
      ];
    };
}
