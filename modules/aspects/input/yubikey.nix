{ ... }:
{
  my.yubikey.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.yubikey-touch-detector ];

      systemd.user.services.yubikey-touch-detector = {
        Unit = {
          Description = "YubiKey touch detector";
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector";
          Environment = [ "YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=true" ];
          Restart = "always";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
