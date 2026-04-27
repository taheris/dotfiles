{ ... }:

{
  my.mouser.homeManager =
    { config, pkgs, ... }:
    {
      home = {
        packages = [ pkgs.mouser ];

        file.mouserConfig = {
          source = ./_mouser/mouser.json;
          target = "${config.xdg.configHome}/Mouser/config.json";
        };
      };

      systemd.user.services.mouser = {
        Unit = {
          Description = "Mouser - Logitech mouse remapper";
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.mouser}/bin/mouser --start-hidden";
          Environment = [ "PYTHONUNBUFFERED=1" ];
          Restart = "always";
          RestartSec = 3;
          KillSignal = "SIGKILL";
          TimeoutStopSec = 5;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      systemd.user.services.mouser-resume = {
        Unit = {
          Description = "Restart Mouser on system resume";
        };

        Service = {
          Type = "exec";
          ExecStart = pkgs.writeShellScript "mouser-resume-watch" ''
            ${pkgs.dbus}/bin/dbus-monitor --system \
              "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" |
              while read -r line; do
                case "$line" in
                  *"boolean false"*)
                    sleep 2
                    ${pkgs.systemd}/bin/systemctl --user restart mouser.service
                    ;;
                esac
              done
          '';
          Restart = "on-failure";
          RestartSec = 5;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
