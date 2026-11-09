{ lib, ... }:

let
  inherit (builtins) fromTOML readFile;
  inherit (lib) concatMapStrings escapeShellArg subtractLists;

  settings = readFile ./_omniwm/settings.toml;
  configuredActions = map (hotkey: hotkey.id) (fromTOML settings).hotkeys;
  requiredActions = import ./_omniwm/hotkeys.nix { inherit lib; };
  unassignedActions = subtractLists configuredActions requiredActions;

in
{
  my.omniwm.homeManager =
    { config, pkgs, ... }:
    let
      managedSettings = "${config.xdg.configHome}/omniwm/settings.nix.toml";
      liveSettings = "${config.xdg.configHome}/omniwm/settings.toml";
      managedShell = "${config.xdg.configHome}/omniwm/shell/shell.nix.toml";
      liveShell = "${config.xdg.configHome}/omniwm/shell/shell.toml";
    in
    {
      xdg.configFile."omniwm/shell/shell.nix.toml" = {
        source = ./_omniwm/shell.toml;

        # Preserve GUI experiments until the managed baseline changes.
        onChange = ''
          run ${pkgs.coreutils}/bin/install -m 0600 -- ${escapeShellArg managedShell} ${escapeShellArg liveShell}
        '';
      };

      xdg.configFile."omniwm/settings.nix.toml" = {
        text =
          settings
          + concatMapStrings (id: ''

            [[hotkeys]]
            binding = "Unassigned"
            id = "${id}"
          '') unassignedActions;

        # Keep the live file writable for editor/GUI experiments. Unchanged
        # rebuilds leave those edits alone; changed Nix settings replace them.
        onChange = ''
          run ${pkgs.coreutils}/bin/install -m 0600 -- ${escapeShellArg managedSettings} ${escapeShellArg liveSettings}
        '';
      };
    };
}
