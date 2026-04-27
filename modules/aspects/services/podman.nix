{ ... }:

{
  my.podman.nixos = {
    virtualisation = {
      containers = {
        enable = true;
        containersConf.settings = {
          engine.compose_warning_logs = false;
        };
      };

      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
