{ ... }:

{
  my.librepods = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.librepods ];

        systemd.user.services.librepods = {
          Unit = {
            Description = "LibrePods AirPods companion";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.librepods}/bin/librepods --hide";
            Restart = "on-failure";
            RestartSec = 5;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };

    nixos = {
      hardware.bluetooth.settings.General = {
        ControllerMode = "dual";
        Experimental = true;
      };

      services.pipewire.wireplumber.extraConfig."51-bluez-avrcp" = {
        "monitor.bluez.properties"."bluez5.dummy-avrcp-player" = true;
      };
    };
  };
}
