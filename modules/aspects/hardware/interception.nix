{ ... }:

{
  my.interception.nixos =
    { pkgs, ... }:
    {
      services.interception-tools = {
        enable = true;
        udevmonConfig = ''
          - JOB: |
              ${pkgs.interception-tools}/bin/intercept -g $DEVNODE | \
              ${pkgs.intercept-fn-keys}/bin/intercept | \
              ${pkgs.interception-tools}/bin/uinput -d $DEVNODE
            DEVICE:
              NAME: "DYGMA DEFY Keyboard"
              EVENTS:
                EV_KEY: [KEY_F17, KEY_F18]
        '';
      };
    };
}
