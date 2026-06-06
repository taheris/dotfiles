{ ... }:

{
  my.thunderbird.homeManager =
    { config, pkgs, ... }:
    let
      inherit (pkgs.formats) json;

      # Use fetchurl rather than fetchFirefoxAddon; the latter re-zips the XPI
      # after patching the manifest which invalidates Mozilla's signature.
      tbkeysXpi = pkgs.fetchurl {
        url = "https://github.com/wshanks/tbkeys/releases/download/v2.4.3/tbkeys.xpi";
        hash = "sha256-2e+T5Nr5kc2s8EykFzWKaJZ2jPUDHh9Cqn4hCuDCLaM=";
      };

    in
    {
      programs.thunderbird = {
        enable = true;

        profiles.default = {
          isDefault = true;
          # auto-enable extensions instead of manual UI approval
          settings."extensions.autoDisableScopes" = 0;
        };
      };

      # profiles.<name>.extensions option expects a layout the XPI doesn't have.
      home.file.".thunderbird/default/extensions/tbkeys@addons.thunderbird.net.xpi".source = tbkeysXpi;

      # tbkeys stores its config in WebExtension storage, which can't be set
      # via user.js. Keep the source of truth here and paste it into the
      # addon's options pane once — `tbkeys` shell alias copies it to clipboard.
      xdg.configFile."tbkeys/mainkeys.json".source = (json { }).generate "tbkeys-mainkeys.json" {
        "j" = "cmd:cmd_nextMsg";
        "k" = "cmd:cmd_previousMsg";
        "o" = "cmd:cmd_openMessage";
        "r" = "cmd:cmd_reply";
        "a" = "cmd:cmd_replyall";
        "f" = "cmd:cmd_forward";
        "d" = "cmd:cmd_delete";
        "s" = "cmd:cmd_markAsFlagged";
        "c" = "func:MsgNewMessage";
        "x" = "tbkeys:closeMessageAndRefresh";
        "n" = "cmd:cmd_nextUnreadMsg";
        "m" = "cmd:cmd_markAsRead";
        "M" = "cmd:cmd_markAllRead";
        "u" = "cmd:cmd_undo";
        "U" = "cmd:cmd_redo";
        "J" = "window.document.getElementById('tabmail-tabs').advanceSelectedTab(-1, true)";
        "K" = "window.document.getElementById('tabmail-tabs').advanceSelectedTab(1, true)";
        "/" = "cmd:cmd_search";
      };

      home.shellAliases.tbkeys = "cat ${config.xdg.configHome}/tbkeys/mainkeys.json | ${pkgs.wl-clipboard}/bin/wl-copy";
    };
}
