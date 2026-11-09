{ ... }:

{
  my.rex.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      managedConfig = "${config.xdg.configHome}/rex/init.nix.lua";
      liveConfig = "${config.xdg.configHome}/rex/init.lua";
    in
    {
      targets.darwin.defaults."com.superlogical.rex" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        "Workspace.terminalFontName" = "MonacoB Nerd Font Mono";
        "Workspace.terminalFontPointSize" = 14.0;
        "Workspace.terminalCursorBlinkIntervalMilliseconds" = 0;
        "Workspace.terminalCursorBlinkUsesCustomInterval" = false;

        "Workspace.darkThemeID" = "merino-dark";
        "Workspace.lightThemeID" = "merino-light";
        "Workspace.paneDensity" = "compact";
        "Workspace.showsPaneHeaders" = false;
        "Workspace.tabStyle" = "horizontal";
        "Workspace.tabIconTintMode" = "off";
        "Workspace.sidebarPosition" = "left";
        "Workspace.sidebarCollapsed" = false;
        "Workspace.inactivePaneFadeMode" = "both";
        "Workspace.usesStandardInactiveWindowPaneStyles" = true;

        "rex.developer-mode-enabled" = true;
        # Enable the experimental Go to Anything UI in Rex 1853. Remove this
        # flag once the new quick switcher is available without it.
        # https://www.superlogical.com/rex/docs/reference/mac-settings.md#setting-experimental-new-quick-switcher
        "Workspace.experiments.usesNewQuickSwitcher" = true;
      };

      xdg.configFile."rex/init.nix.lua" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        source = ./_rex/init.lua;

        # Keep the live config writable for experiments. Unchanged rebuilds
        # preserve edits; changes to the Nix baseline replace them.
        onChange = ''
          run ${pkgs.coreutils}/bin/install -m 0600 -- ${lib.escapeShellArg managedConfig} ${lib.escapeShellArg liveConfig}
        '';
      };
    };
}
